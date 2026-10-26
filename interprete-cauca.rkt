#lang eopl
;Autores: Luis David Mendoza Manzano - 2067621

;; Taller 2 — El intérprete de Cauca.
;; Fachada: reúne los seis módulos de src/ y reexporta todo lo que
;; definen, de modo que quien la requiera vea todos los nombres sin
;; requerir los módulos uno por uno.
;;
;;   src/sintaxis.rkt    especificación léxica y gramatical, scanner, parser
;;   src/valores.rkt     el valor procedimiento
;;   src/ambiente.rkt    el TAD ambiente y el ambiente inicial
;;   src/primitivas.rkt  las primitivas y sus verificaciones
;;   src/interprete.rkt  la evaluación y la aplicación de procedimientos
;;   src/interfaz.rkt    el punto de entrada y el REPL
;;
;; Los require van en un solo sentido. Racket no carga dos módulos que se
;; requieran entre sí.

(require "src/sintaxis.rkt")
(require "src/valores.rkt")
(require "src/ambiente.rkt")
(require "src/primitivas.rkt")
(require "src/interprete.rkt")
(require "src/interfaz.rkt")

(provide (all-from-out "src/sintaxis.rkt"
                       "src/valores.rkt"
                       "src/ambiente.rkt"
                       "src/primitivas.rkt"
                       "src/interprete.rkt"
                       "src/interfaz.rkt"))

;;; ==========================================================
;;; Ejemplos
;;; ==========================================================

#|
  Ejemplos del enunciado, ejecutados con el intérprete: cada expresión va
  con el resultado que produce escrito al lado. Los errores muestran el
  mensaje que levanta eopl:error. Las pruebas con rackunit viven en
  pruebas-cauca.rkt, que verifica estos mismos casos y varios más.

  Scanner (token = (clase valor linea); los literales llevan una clase generada por SLLGEN)
    (scanner "x5 -7 3.5")
      => ((identificador x5 1) (numero -7 1) (numero 3.5 1))
    (scanner "add1(x)")
      => ((literal-string47 "add1" 1) (literal-string47 "(" 1) (identificador x 1) (literal-string47 ")" 1))
    (scanner "// un comentario no produce tokens\n42")
      => ((numero 42 2))
    (scanner "if true then 1 else 2 end")
      => ((literal-string47 "if" 1) (literal-string47 "true" 1) (literal-string47 "then" 1) (numero 1 1) (literal-string47 "else" 1) (numero 2 1) (literal-string47 "end" 1))
    (scanner "aplicar-n")
      => ((identificador aplicar 1) (literal-string47 "-" 1) (identificador n 1))
    (scanner "letrec f (a) = a in 0 end")
      => ((literal-string47 "letrec" 1) (identificador f 1) (literal-string47 "(" 1) (identificador a 1) (literal-string47 ")" 1) (literal-string47 "=" 1) (identificador a 1) (literal-string47 "in" 1) (numero 0 1) (literal-string47 "end" 1))

  Parser (árbol de sintaxis abstracta)
    (parser "42")
      => #(struct:a-program #(struct:lit-exp 42))
    (parser "n")
      => #(struct:a-program #(struct:var-exp n))
    (parser "+(1, x)")
      => #(struct:a-program #(struct:prim-exp #(struct:sum-prim) (#(struct:lit-exp 1) #(struct:var-exp x))))
    (parser "if true then 1 else 2 end")
      => #(struct:a-program #(struct:if-exp #(struct:true-exp) #(struct:lit-exp 1) #(struct:lit-exp 2)))
    (parser "let x = 1 y = 2 in *(x, y) end")
      => #(struct:a-program #(struct:let-exp (x y) (#(struct:lit-exp 1) #(struct:lit-exp 2)) #(struct:prim-exp #(struct:mult-prim) (#(struct:var-exp x) #(struct:var-exp y)))))
    (parser "proc (a, b) +(a, b) end")
      => #(struct:a-program #(struct:proc-exp (a b) #(struct:prim-exp #(struct:sum-prim) (#(struct:var-exp a) #(struct:var-exp b)))))
    (parser "apply f (1, 2)")
      => #(struct:a-program #(struct:app-exp #(struct:var-exp f) (#(struct:lit-exp 1) #(struct:lit-exp 2))))
    (parser "letrec f (a) = a in apply f (1) end")
      => #(struct:a-program #(struct:letrec-exp (f) ((a)) (#(struct:var-exp a)) #(struct:app-exp #(struct:var-exp f) (#(struct:lit-exp 1)))))
    (parser "case 1 of 1 => 2 otherwise => 0 end")
      => #(struct:a-program #(struct:case-exp #(struct:lit-exp 1) (1) (#(struct:lit-exp 2)) #(struct:lit-exp 0)))

  Ejecución del lenguaje base (Parte 1)
    (interpretar "42")
      => 42
    (interpretar "n")
      => 10
    (interpretar "-(10, 3, 2)")
      => 5
    (interpretar "/(100, 5, 2)")
      => 10
    (interpretar "add1(n)")
      => 11
    (interpretar "not(true)")
      => #f
    (interpretar ">=(m, m)")
      => #t
    (interpretar "if >(n, m) then n else m end")
      => 10
    (interpretar "let x = 2 y = 3 in *(x, y) end")
      => 6
    (interpretar "let x = 1 in let x = 2 in x end end")
      => 2
    (interpretar "// el area de un rectangulo, con el condicional que valida los lados\nlet base = 8\n    altura = 5\nin\n  if and(>(base, 0), >(altura, 0))\n  then *(base, altura)\n  else 0\n  end\nend")
      => 40
    (interpretar "if n then 1 else 2 end")
      => error: if-exp: La condicion debe ser booleana y llego 10
    (interpretar "z")
      => error: apply-env: La variable z no esta ligada
    (interpretar "/(1, 0)")
      => error: /: Division por cero
    (interpretar "+(1, true)")
      => error: +: Se esperaba un numero y llego #t

  Primitivas nuevas (Parte 2)
    (interpretar "abs(-7)")
      => 7
    (interpretar "abs(7)")
      => 7
    (interpretar "abs(-3.5)")
      => 3.5
    (interpretar "abs(true)")
      => error: abs: Se esperaba un numero y llego #t
    (interpretar "mcd(12, 18)")
      => 6
    (interpretar "mcd(7, 13)")
      => 1
    (interpretar "mcd(12, 18, 24)")
      => 6
    (interpretar "mcd(1.5, 2)")
      => error: mcd: Se esperaba un entero y llego 1.5
    (interpretar "mcm(4, 6)")
      => 12
    (interpretar "mcm(3, 5)")
      => 15
    (interpretar "mcm(2, 3, 4)")
      => 12
    (interpretar "mcm(4)")
      => error: mcm: Se esperaban al menos 2 argumentos y llegaron 1
    (interpretar "promedio(1, 2, 3, 4)")
      => 5/2
    (interpretar "promedio(10)")
      => 10
    (interpretar "promedio(n, m)")
      => 13/2
    (interpretar "promedio()")
      => error: promedio: Se esperaban al menos 1 argumentos y llegaron 0
    (interpretar "xor(true, false)")
      => #t
    (interpretar "xor(true, true)")
      => #f
    (interpretar "xor(false, false)")
      => #f
    (interpretar "xor(1, true)")
      => error: xor: Se esperaba un booleano y llego 1
    (interpretar "implica(true, false)")
      => #f
    (interpretar "implica(false, false)")
      => #t
    (interpretar "implica(true, true)")
      => #t
    (interpretar "implica(true)")
      => error: implica: Se esperaban exactamente 2 argumentos y llegaron 1
    (interpretar "entre(5, 1, 10)")
      => #t
    (interpretar "entre(1, 1, 10)")
      => #t
    (interpretar "entre(11, 1, 10)")
      => #f
    (interpretar "entre(1, 2)")
      => error: entre: Se esperaban exactamente 3 argumentos y llegaron 2

  Procedimientos (Parte 3)
    (interpretar "let f = proc () 7 end in apply f () end")
      => 7
    (interpretar "let escalar = proc (v) *(v, 2) end in apply escalar (21) end")
      => 42
    (interpretar "let f = proc (a, b, c) +(a, b, c) end in apply f (1, 2, 3) end")
      => 6
    (interpretar "let aplicardos = proc (f, x) apply f (apply f (x)) end\n    doble = proc (v) *(v, 2) end\nin apply aplicardos (doble, 5) end")
      => 20
    (interpretar "let sumador = proc (a) proc (b) +(a, b) end end\nin let suma3 = apply sumador (3)\n   in apply suma3 (4) end\nend")
      => 7
    (interpretar "let factor = 10\nin\n  let escalar = proc (v) *(v, factor) end\n  in\n    let factor = 1000\n    in\n      apply escalar (5)\n    end\n  end\nend")
      => 50
    (interpretar "apply 5 (1)")
      => error: app-exp: Se intento aplicar algo que no es un procedimiento: 5
    (interpretar "let f = proc (a, b) +(a, b) end in apply f (1) end")
      => error: apply-procedure: El procedimiento espera 2 argumentos y recibio 1

  Recursión (Parte 4.1)
    (interpretar "letrec\n  potencia (base, exp) = if ==(exp, 0)\n                         then 1\n                         else *(base, apply potencia (base, sub1(exp)))\n                         end\nin\n  apply potencia (2, 10)\nend")
      => 1024
    (interpretar "letrec factorial (n) = if ==(n, 0) then 1 else *(n, apply factorial (sub1(n))) end\nin apply factorial (5) end")
      => 120
    (interpretar "letrec\n  par? (n) = if ==(n, 0) then true else apply impar? (sub1(n)) end\n  impar? (n) = if ==(n, 0) then false else apply par? (sub1(n)) end\nin apply par? (10) end")
      => #t
    (interpretar "letrec\n  aplicarn (f, x, veces) = if ==(veces, 0)\n                           then x\n                           else apply f (apply aplicarn (f, x, sub1(veces)))\n                           end\nin let doble = proc (v) *(v, 2) end\n   in apply aplicarn (doble, 1, 5) end\nend")
      => 32
    (interpretar "let fact = proc (n) if ==(n, 0) then 1 else *(n, apply fact (sub1(n))) end end\nin apply fact (5) end")
      => error: apply-env: La variable fact no esta ligada

  case (Parte 4.2)
    (interpretar "let dia = 3\nin\n  case dia\n    of 1 => 100\n    of 3 => 300\n    of 7 => 700\n    otherwise => 0\n  end\nend")
      => 300
    (interpretar "let dia = 5\nin case dia of 1 => 100 of 3 => 300 otherwise => 0 end end")
      => 0
    (interpretar "case +(1, 2) of 2 => 20 of 3 => 30 otherwise => 0 end")
      => 30
    (interpretar "case true of 1 => 1 otherwise => 0 end")
      => error: case-exp: El valor de control debe ser un numero y llego #t
|#