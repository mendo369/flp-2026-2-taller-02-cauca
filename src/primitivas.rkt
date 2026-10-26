#lang eopl
;Autores: Luis David Mendoza Manzano - 2067621

;; Taller 2 — El intérprete de Cauca.
;; Las primitivas del lenguaje y las verificaciones de tipo y de
;; cantidad de argumentos que cada una exige. Requiere sintaxis.rkt.
;;
;; Aridades: +, -, *, / son n-arias; add1, sub1, not y abs son unarias;
;; las relacionales, and, or, xor e implica son binarias; entre es
;; ternaria; mcd y mcm son n-arias sobre enteros con al menos dos
;; argumentos; promedio es n-aria sobre números con al menos uno.
;;
;; Decisiones sobre lo que el enunciado no fija:
;;   - La resta y la división n-arias son las del curso: a - b - c es
;;     a - (b + c), y a / b / c es a / (b * c).
;;   - La división es exacta: (/ 5 2) da 5/2, y promedio(1, 2, 3, 4) da 5/2.
;;   - Dividir por cero levanta eopl:error.
;;   - Un entero para mcd y mcm es un entero exacto (1.5 no lo es).
;;   - Las primitivas evalúan todos sus argumentos antes de aplicarse, de
;;     modo que and y or no hacen cortocircuito.

(require "sintaxis.rkt")

;; exigir-numeros : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son números; si no, levanta
;; eopl:error a nombre de quien hizo la verificación.
;; Ejemplo: (exigir-numeros '(1 2.5) 'abs) => #t
(define exigir-numeros
  (lambda (args quien)
    (cond
      ((null? args) #t)
      ((number? (car args)) (exigir-numeros (cdr args) quien))
      (else (eopl:error quien "Se esperaba un numero y llego ~s" (car args))))))

;; exigir-enteros : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son enteros; si no, levanta error.
;; Ejemplo: (exigir-enteros '(12 18) 'mcd) => #t
(define exigir-enteros
  (lambda (args quien)
    (cond
      ((null? args) #t)
      ((and (integer? (car args)) (exact? (car args)))
       (exigir-enteros (cdr args) quien))
      (else (eopl:error quien "Se esperaba un entero y llego ~s" (car args))))))

;; exigir-booleanos : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son booleanos; si no, levanta error.
;; Ejemplo: (exigir-booleanos '(#t #f) 'xor) => #t
(define exigir-booleanos
  (lambda (args quien)
    (cond
      ((null? args) #t)
      ((boolean? (car args)) (exigir-booleanos (cdr args) quien))
      (else (eopl:error quien "Se esperaba un booleano y llego ~s" (car args))))))

;; exigir-cantidad : lista x int x symbol -> boolean
;; Retorna #t si llegaron exactamente n argumentos; si no, levanta error.
;; Ejemplo: (exigir-cantidad '(1 2 3) 3 'entre) => #t
(define exigir-cantidad
  (lambda (args n quien)
    (if (= (length args) n)
        #t
        (eopl:error quien "Se esperaban exactamente ~s argumentos y llegaron ~s"
                    n (length args)))))

;; exigir-minimo : lista x int x symbol -> boolean
;; Retorna #t si llegaron al menos n argumentos; si no, levanta error.
;; Ejemplo: (exigir-minimo '(12 18) 2 'mcd) => #t
(define exigir-minimo
  (lambda (args n quien)
    (if (>= (length args) n)
        #t
        (eopl:error quien "Se esperaban al menos ~s argumentos y llegaron ~s"
                    n (length args)))))

;; suma-lista : lista de números -> número
;; Suma todos los elementos; la lista vacía suma 0.
(define suma-lista
  (lambda (lst)
    (if (null? lst)
        0
        (+ (car lst) (suma-lista (cdr lst))))))

;; producto-lista : lista de números -> número
;; Multiplica todos los elementos; la lista vacía multiplica 1.
(define producto-lista
  (lambda (lst)
    (if (null? lst)
        1
        (* (car lst) (producto-lista (cdr lst))))))

;; mcd-dos : entero x entero -> entero
;; Máximo común divisor de dos enteros por el algoritmo de Euclides.
;; Ejemplo: (mcd-dos 12 18) => 6
(define mcd-dos
  (lambda (a b)
    (if (= b 0)
        (abs a)
        (mcd-dos b (remainder a b)))))

;; mcm-dos : entero x entero -> entero
;; Mínimo común múltiplo de dos enteros; si alguno es 0, el resultado es 0.
;; Ejemplo: (mcm-dos 4 6) => 12
(define mcm-dos
  (lambda (a b)
    (if (or (= a 0) (= b 0))
        0
        (/ (abs (* a b)) (mcd-dos a b)))))

;; reducir-mcd : lista de enteros (no vacía) -> entero
;; Pliega mcd-dos sobre la lista.
(define reducir-mcd
  (lambda (lst)
    (if (null? (cdr lst))
        (abs (car lst))
        (mcd-dos (car lst) (reducir-mcd (cdr lst))))))

;; reducir-mcm : lista de enteros (no vacía) -> entero
;; Pliega mcm-dos sobre la lista.
(define reducir-mcm
  (lambda (lst)
    (if (null? (cdr lst))
        (abs (car lst))
        (mcm-dos (car lst) (reducir-mcm (cdr lst))))))

;; dividir : lista de números (no vacía) -> número
;; El primero dividido por el producto del resto; error si ese producto
;; es cero.
(define dividir
  (lambda (args)
    (let ((divisor (producto-lista (cdr args))))
      (if (= divisor 0)
          (eopl:error '/ "Division por cero")
          (/ (car args) divisor)))))

;; evaluar-primitiva : primitiva x lista de valores -> valor
;; Verifica la cantidad y el tipo de los argumentos y aplica la
;; primitiva. Se resuelve con cases sobre el datatype primitiva.
;; Ejemplo: (evaluar-primitiva (sum-prim) '(1 2 3)) => 6
(define evaluar-primitiva
  (lambda (prim args)
    (cases primitiva prim
      (sum-prim ()
        (begin (exigir-numeros args '+)
               (suma-lista args)))
      (minus-prim ()
        (begin (exigir-minimo args 1 '-)
               (exigir-numeros args '-)
               (- (car args) (suma-lista (cdr args)))))
      (mult-prim ()
        (begin (exigir-numeros args '*)
               (producto-lista args)))
      (div-prim ()
        (begin (exigir-minimo args 1 '/)
               (exigir-numeros args '/)
               (dividir args)))
      (add-prim ()
        (begin (exigir-cantidad args 1 'add1)
               (exigir-numeros args 'add1)
               (+ (car args) 1)))
      (sub-prim ()
        (begin (exigir-cantidad args 1 'sub1)
               (exigir-numeros args 'sub1)
               (- (car args) 1)))
      (mayor-prim ()
        (begin (exigir-cantidad args 2 '>)
               (exigir-numeros args '>)
               (> (car args) (cadr args))))
      (mayorigual-prim ()
        (begin (exigir-cantidad args 2 '>=)
               (exigir-numeros args '>=)
               (>= (car args) (cadr args))))
      (menor-prim ()
        (begin (exigir-cantidad args 2 '<)
               (exigir-numeros args '<)
               (< (car args) (cadr args))))
      (menorigual-prim ()
        (begin (exigir-cantidad args 2 '<=)
               (exigir-numeros args '<=)
               (<= (car args) (cadr args))))
      (igual-prim ()
        (begin (exigir-cantidad args 2 '==)
               (exigir-numeros args '==)
               (= (car args) (cadr args))))
      (not-prim ()
        (begin (exigir-cantidad args 1 'not)
               (exigir-booleanos args 'not)
               (not (car args))))
      (and-prim ()
        (begin (exigir-cantidad args 2 'and)
               (exigir-booleanos args 'and)
               (and (car args) (cadr args))))
      (or-prim ()
        (begin (exigir-cantidad args 2 'or)
               (exigir-booleanos args 'or)
               (or (car args) (cadr args))))
      (abs-prim ()
        (begin (exigir-cantidad args 1 'abs)
               (exigir-numeros args 'abs)
               (abs (car args))))
      (mcd-prim ()
        (begin (exigir-minimo args 2 'mcd)
               (exigir-enteros args 'mcd)
               (reducir-mcd args)))
      (mcm-prim ()
        (begin (exigir-minimo args 2 'mcm)
               (exigir-enteros args 'mcm)
               (reducir-mcm args)))
      (promedio-prim ()
        (begin (exigir-minimo args 1 'promedio)
               (exigir-numeros args 'promedio)
               (/ (suma-lista args) (length args))))
      (xor-prim ()
        (begin (exigir-cantidad args 2 'xor)
               (exigir-booleanos args 'xor)
               (not (eq? (car args) (cadr args)))))
      (implica-prim ()
        (begin (exigir-cantidad args 2 'implica)
               (exigir-booleanos args 'implica)
               (or (not (car args)) (cadr args))))
      (entre-prim ()
        (begin (exigir-cantidad args 3 'entre)
               (exigir-numeros args 'entre)
               (and (<= (cadr args) (car args))
                    (<= (car args) (caddr args))))))))

(provide (all-defined-out))