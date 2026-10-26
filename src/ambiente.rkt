#lang eopl
;Autores: Luis David Mendoza Manzano - 2067621

;; Taller 2 — El intérprete de Cauca.
;; El TAD ambiente, la búsqueda de ligaduras y el ambiente inicial.
;; Requiere sintaxis.rkt y valores.rkt.
;;
;; Aquí se declara con define-datatype el tipo ambiente, con tres
;; variantes:
;;
;;   ambiente-vacio()
;;   ambiente-extendido(ids, valores, env)
;;     ids      (list-of symbol?)
;;     valores  list?
;;     env      ambiente?
;;   ambiente-recursivo(proc-names, idss, bodies, env)
;;     proc-names  (list-of symbol?)   los nombres declarados en el letrec
;;     idss        list?               la lista de parámetros de cada uno
;;     bodies      (list-of expresion?) los cuerpos, guardados sin evaluar
;;     env         ambiente?
;;
;; La variante recursiva no construye clausuras: las arma apply-env en el
;; momento de la búsqueda, y el ambiente que les entrega es el propio
;; ambiente-recursivo (EOPL, sección 3.4, figura 3.9).

(require "sintaxis.rkt")
(require "valores.rkt")

(define-datatype ambiente ambiente?
  (ambiente-vacio)
  (ambiente-extendido
   (ids (list-of symbol?))
   (valores list?)
   (env ambiente?))
  (ambiente-recursivo
   (proc-names (list-of symbol?))
   (idss list?)
   (bodies (list-of expresion?))
   (env ambiente?)))

;; apply-env : ambiente x symbol -> valor
;; Busca el identificador en el ambiente, respetando el shadowing de las
;; ligaduras más recientes, y levanta eopl:error si no está ligado.
;; En un ambiente-extendido devuelve el valor guardado. En un
;; ambiente-recursivo, si el nombre es uno de los declarados, arma en ese
;; momento una cerradura cuyo ambiente es el propio ambiente-recursivo;
;; si no, sigue por el ambiente que extiende.
;; Ejemplo: (apply-env (ambiente-inicial) 'n) => 10
(define apply-env
  (lambda (env id)
    (cases ambiente env
      (ambiente-vacio ()
        (eopl:error 'apply-env "La variable ~s no esta ligada" id))
      (ambiente-extendido (ids valores old-env)
        (letrec ((buscar-valor
                  (lambda (ids valores)
                    (cond
                      ((null? ids) (apply-env old-env id))
                      ((equal? (car ids) id) (car valores))
                      (else (buscar-valor (cdr ids) (cdr valores)))))))
          (buscar-valor ids valores)))
      (ambiente-recursivo (proc-names idss bodies old-env)
        (letrec ((buscar-proc
                  (lambda (proc-names idss bodies)
                    (cond
                      ((null? proc-names) (apply-env old-env id))
                      ((equal? (car proc-names) id)
                       (cerradura (car idss) (car bodies) env))
                      (else (buscar-proc (cdr proc-names)
                                         (cdr idss)
                                         (cdr bodies)))))))
          (buscar-proc proc-names idss bodies))))))

;; ambiente-inicial : -> ambiente
;; El ambiente con que arranca todo programa:
;; n = 10, m = 3, p = 7, q = 2, r = 5.
;; Ejemplo: (apply-env (ambiente-inicial) 'q) => 2
(define ambiente-inicial
  (lambda ()
    (ambiente-extendido '(n m p q r)
                        '(10 3 7 2 5)
                        (ambiente-vacio))))

(provide (all-defined-out))