#lang eopl
;Autores: Luis David Mendoza Manzano - 2067621

;; Taller 2 — El intérprete de Cauca.
;; El recorrido de la sintaxis abstracta y la aplicación de
;; procedimientos. Requiere sintaxis.rkt, valores.rkt, ambiente.rkt y
;; primitivas.rkt.
;;
;; apply-procedure vive aquí y no en valores.rkt porque llama a
;; evaluar-expresion.

(require "sintaxis.rkt")
(require "valores.rkt")
(require "ambiente.rkt")
(require "primitivas.rkt")

;; apply-procedure : procval x lista de valores -> valor
;; Verifica que la cantidad de argumentos coincida con la de parámetros
;; y evalúa el cuerpo en el ambiente de la clausura extendido con las
;; ligaduras de los parámetros, no en el ambiente de la llamada. Levanta
;; eopl:error si las cantidades no coinciden.
;; Ejemplo: aplicar la clausura de proc (x) add1(x) end a la lista (4)
;;   => 5
(define apply-procedure
  (lambda (proc args)
    (cases procval proc
      (cerradura (ids body env)
        (if (= (length ids) (length args))
            (evaluar-expresion body (ambiente-extendido ids args env))
            (eopl:error 'apply-procedure
                        "El procedimiento espera ~s argumentos y recibio ~s"
                        (length ids) (length args)))))))

;; evaluar-programa : programa -> valor
;; Punto de entrada: evalúa la expresión del programa en el ambiente
;; inicial.
;; Ejemplo: (evaluar-programa (a-program (var-exp 'n))) => 10
(define evaluar-programa
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp)
        (evaluar-expresion exp (ambiente-inicial))))))

;; evaluar-rands : lista de expresiones x ambiente -> lista de valores
;; Evalúa las expresiones de izquierda a derecha en el mismo ambiente.
;; Ejemplo: (evaluar-rands (list (lit-exp 1) (var-exp 'n)) (ambiente-inicial))
;;   => (1 10)
(define evaluar-rands
  (lambda (rands env)
    (if (null? rands)
        '()
        (let ((primero (evaluar-expresion (car rands) env)))
          (cons primero (evaluar-rands (cdr rands) env))))))

;; elegir-rama : valor x lista de números x lista de expresiones x
;;               expresion x ambiente -> valor
;; Recorre las ramas de un case en orden: evalúa la acción de la primera
;; cuyo literal es igual al valor de control, y si no hay ninguna evalúa
;; la rama otherwise. El valor de control ya viene evaluado.
(define elegir-rama
  (lambda (control valores acciones default env)
    (cond
      ((null? valores) (evaluar-expresion default env))
      ((= control (car valores)) (evaluar-expresion (car acciones) env))
      (else (elegir-rama control (cdr valores) (cdr acciones) default env)))))

;; evaluar-expresion : expresion x ambiente -> valor
;; Recorre el árbol de sintaxis abstracta con cases y evalúa cada
;; variante según la semántica del enunciado. El if liga el resultado de
;; la condición a test-value, lo verifica con boolean? y solo entonces
;; ramifica; el case evalúa la expresión de control una sola vez.
;; Ejemplo: (evaluar-expresion (lit-exp 7) (ambiente-inicial)) => 7
(define evaluar-expresion
  (lambda (exp env)
    (cases expresion exp
      (lit-exp (dato) dato)
      (var-exp (id) (apply-env env id))
      (true-exp () #t)
      (false-exp () #f)
      (prim-exp (prim rands)
        (evaluar-primitiva prim (evaluar-rands rands env)))
      (if-exp (test true-exp false-exp)
        (let ((test-value (evaluar-expresion test env)))
          (if (boolean? test-value)
              (if test-value
                  (evaluar-expresion true-exp env)
                  (evaluar-expresion false-exp env))
              (eopl:error 'if-exp
                          "La condicion debe ser booleana y llego ~s"
                          test-value))))
      (let-exp (ids rands body)
        (evaluar-expresion body
                           (ambiente-extendido ids (evaluar-rands rands env) env)))
      (proc-exp (ids body)
        (cerradura ids body env))
      (app-exp (rator rands)
        (let ((proc (evaluar-expresion rator env)))
          (if (procval? proc)
              (apply-procedure proc (evaluar-rands rands env))
              (eopl:error 'app-exp
                          "Se intento aplicar algo que no es un procedimiento: ~s"
                          proc))))
      (letrec-exp (proc-names idss bodies letrec-body)
        (evaluar-expresion letrec-body
                           (ambiente-recursivo proc-names idss bodies env)))
      (case-exp (control valores acciones default)
        (let ((control-value (evaluar-expresion control env)))
          (if (number? control-value)
              (elegir-rama control-value valores acciones default env)
              (eopl:error 'case-exp
                          "El valor de control debe ser un numero y llego ~s"
                          control-value)))))))

(provide (all-defined-out))