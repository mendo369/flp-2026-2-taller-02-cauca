#lang eopl
;Autores: Luis David Mendoza Manzano - 2067621

;; Taller 2 — El intérprete de Cauca.
;; El punto de entrada y el REPL. Requiere sintaxis.rkt e interprete.rkt.

(require "sintaxis.rkt")
(require "interprete.rkt")

;; interpretar : string -> valor
;; Analiza el texto de un programa con el parser y evalúa el árbol
;; resultante con evaluar-programa.
;; Ejemplo: (interpretar "+(n, m)") => 13
(define interpretar
  (lambda (texto)
    (evaluar-programa (parser texto))))

;; interpretador : -> void
;; REPL de Cauca, que se abre con (interpretador). Se construye con
;; sllgen:make-rep-loop sobre evaluar-programa y el parser de flujo que
;; da sllgen:make-stream-parser; make-rep-loop devuelve el ciclo, que se
;; invoca aquí. Lee un programa por línea y escribe su valor.
(define interpretador
  (lambda ()
    ((sllgen:make-rep-loop
      "--> "
      evaluar-programa
      (sllgen:make-stream-parser especificacion-lexica especificacion-gramatical)))))

(provide (all-defined-out))