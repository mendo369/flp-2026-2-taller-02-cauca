#lang eopl
;Autores: Luis David Mendoza Manzano - 2067621

;; Taller 2 — El intérprete de Cauca.
;; Batería de pruebas con rackunit. Llega escrita en el fork y no se
;; modifica: las pruebas del grupo se agregan después, en suites nuevas
;; que se suman a la cuenta de fallidas del final.
;;
;; Requiere solamente la fachada, nunca un módulo de src/ por separado.
;;
;; Se ejecuta con:  racket pruebas-cauca.rkt

(require rackunit)
(require rackunit/text-ui)
(require (only-in racket/base exn:fail?))
(require "interprete-cauca.rkt")

;; corre : string -> valor
(define corre (lambda (texto) (interpretar texto)))

(define base
  (test-suite
   "Parte 1: interprete base"
   (test-case "literales y variables del ambiente inicial"
              (check-equal? (corre "42") 42)
              (check-equal? (corre "-7") -7)
              (check-equal? (corre "3.5") 3.5)
              (check-equal? (corre "n") 10)
              (check-equal? (corre "r") 5))
   (test-case "booleanos"
              (check-equal? (corre "true") #t)
              (check-equal? (corre "false") #f))
   (test-case "primitivas aritmeticas n-arias"
              (check-equal? (corre "+(1, 2, 3)") 6)
              (check-equal? (corre "-(10, 3, 2)") 5)
              (check-equal? (corre "*(2, 3, 4)") 24)
              (check-equal? (corre "/(100, 5, 2)") 10))
   (test-case "primitivas unarias"
              (check-equal? (corre "add1(n)") 11)
              (check-equal? (corre "sub1(n)") 9)
              (check-equal? (corre "not(true)") #f))
   (test-case "primitivas relacionales"
              (check-equal? (corre ">(n, m)") #t)
              (check-equal? (corre ">=(m, m)") #t)
              (check-equal? (corre "<(q, r)") #t)
              (check-equal? (corre "<=(r, q)") #f)
              (check-equal? (corre "==(n, 10)") #t))
   (test-case "primitivas booleanas binarias"
              (check-equal? (corre "and(true, false)") #f)
              (check-equal? (corre "or(true, false)") #t))
   (test-case "condicional"
              (check-equal? (corre "if >(n, m) then n else m end") 10)
              (check-equal? (corre "if <(n, m) then n else m end") 3))
   (test-case "ligaduras locales"
              (check-equal? (corre "let x = 2 y = 3 in *(x, y) end") 6)
              (check-equal? (corre "let x = 1 in let x = 2 in x end end") 2)
              (check-equal? (corre "let x = 1 in +(x, n) end") 11))
   (test-case "el ejemplo del area del rectangulo"
              (check-equal? (corre "// el area de un rectangulo, con el condicional que valida los lados
let base = 8
    altura = 5
in
  if and(>(base, 0), >(altura, 0))
  then *(base, altura)
  else 0
  end
end") 40))
   (test-case "la condicion del if debe ser booleana"
              (check-exn exn:fail? (lambda () (corre "if n then 1 else 2 end"))))
   (test-case "una variable no ligada es un error"
              (check-exn exn:fail? (lambda () (corre "z"))))
   (test-case "los comentarios se ignoran"
              (check-equal? (corre "// esto no cuenta
7") 7))))

(define primitivas-nuevas
  (test-suite
   "Parte 2: primitivas nuevas"
   (test-case "abs"
              (check-equal? (corre "abs(-7)") 7)
              (check-equal? (corre "abs(7)") 7)
              (check-equal? (corre "abs(-3.5)") 3.5))
   (test-case "mcd"
              (check-equal? (corre "mcd(12, 18)") 6)
              (check-equal? (corre "mcd(7, 13)") 1)
              (check-equal? (corre "mcd(12, 18, 24)") 6))
   (test-case "mcm"
              (check-equal? (corre "mcm(4, 6)") 12)
              (check-equal? (corre "mcm(3, 5)") 15)
              (check-equal? (corre "mcm(2, 3, 4)") 12))
   (test-case "promedio"
              (check-equal? (corre "promedio(1, 2, 3, 4)") 5/2)
              (check-equal? (corre "promedio(10)") 10)
              (check-equal? (corre "promedio(n, m)") 13/2))
   (test-case "xor"
              (check-equal? (corre "xor(true, false)") #t)
              (check-equal? (corre "xor(true, true)") #f)
              (check-equal? (corre "xor(false, false)") #f))
   (test-case "implica"
              (check-equal? (corre "implica(true, false)") #f)
              (check-equal? (corre "implica(false, false)") #t)
              (check-equal? (corre "implica(true, true)") #t))
   (test-case "entre"
              (check-equal? (corre "entre(5, 1, 10)") #t)
              (check-equal? (corre "entre(1, 1, 10)") #t)
              (check-equal? (corre "entre(11, 1, 10)") #f))
   (test-case "las primitivas verifican el tipo de sus argumentos"
              (check-exn exn:fail? (lambda () (corre "mcd(1.5, 2)")))
              (check-exn exn:fail? (lambda () (corre "xor(1, true)")))
              (check-exn exn:fail? (lambda () (corre "abs(true)")))
              (check-exn exn:fail? (lambda () (corre "entre(1, 2)"))))))

(define procedimientos
  (test-suite
   "Parte 3: procedimientos y clausuras"
   (test-case "procedimiento de un parametro"
              (check-equal? (corre "let escalar = proc (v) *(v, 2) end
                                    in apply escalar (21) end") 42))
   (test-case "procedimiento sin parametros"
              (check-equal? (corre "let f = proc () 7 end in apply f () end") 7))
   (test-case "procedimiento de varios parametros"
              (check-equal? (corre "let f = proc (a, b, c) +(a, b, c) end
                                    in apply f (1, 2, 3) end") 6))
   (test-case "un procedimiento recibe otro como argumento"
              (check-equal? (corre "let aplicardos = proc (f, x) apply f (apply f (x)) end
                                        doble = proc (v) *(v, 2) end
                                    in apply aplicardos (doble, 5) end") 20))
   (test-case "un procedimiento retorna otro procedimiento"
              ;; el resultado de una aplicacion se liga antes de volver a
              ;; aplicarlo: <expresion> no puede empezar con parentesis
              (check-equal? (corre "let sumador = proc (a) proc (b) +(a, b) end end
                                    in let suma3 = apply sumador (3)
                                       in apply suma3 (4) end
                                    end") 7))
   (test-case "el cuerpo se evalua en el ambiente de la definicion"
              (check-equal? (corre "let factor = 10
in
  let escalar = proc (v) *(v, factor) end
  in
    let factor = 1000
    in
      apply escalar (5)
    end
  end
end") 50))
   (test-case "aplicar algo que no es procedimiento es un error"
              (check-exn exn:fail? (lambda () (corre "apply 5 (1)"))))
   (test-case "la cantidad de argumentos debe coincidir"
              (check-exn exn:fail?
                         (lambda () (corre "let f = proc (a, b) +(a, b) end
                                            in apply f (1) end"))))))

(define recursion-y-case
  (test-suite
   "Parte 4: recursion y seleccion por valor"
   (test-case "el ejemplo de potencia"
              (check-equal? (corre "letrec
  potencia (base, exp) = if ==(exp, 0)
                         then 1
                         else *(base, apply potencia (base, sub1(exp)))
                         end
in
  apply potencia (2, 10)
end") 1024))
   (test-case "recursion simple"
              (check-equal? (corre "letrec
  factorial (n) = if ==(n, 0) then 1 else *(n, apply factorial (sub1(n))) end
in apply factorial (5) end") 120))
   (test-case "recursion mutua en el mismo letrec"
              (check-equal? (corre "letrec
  par? (n) = if ==(n, 0) then true else apply impar? (sub1(n)) end
  impar? (n) = if ==(n, 0) then false else apply par? (sub1(n)) end
in apply par? (10) end") #t)
              (check-equal? (corre "letrec
  par? (n) = if ==(n, 0) then true else apply impar? (sub1(n)) end
  impar? (n) = if ==(n, 0) then false else apply par? (sub1(n)) end
in apply impar? (7) end") #t))
   (test-case "letrec con un procedimiento pasado como argumento"
              (check-equal? (corre "letrec
  aplicarn (f, x, veces) = if ==(veces, 0)
                           then x
                           else apply f (apply aplicarn (f, x, sub1(veces)))
                           end
in let doble = proc (v) *(v, 2) end
   in apply aplicarn (doble, 1, 5) end
end") 32))
   (test-case "el ejemplo de case"
              (check-equal? (corre "let dia = 3
in
  case dia
    of 1 => 100
    of 3 => 300
    of 7 => 700
    otherwise => 0
  end
end") 300))
   (test-case "case con la rama otherwise activa"
              (check-equal? (corre "let dia = 5
in case dia of 1 => 100 of 3 => 300 otherwise => 0 end end") 0))
   (test-case "case evalua la expresion de control una sola vez"
              (check-equal? (corre "case +(1, 2) of 2 => 20 of 3 => 30 otherwise => 0 end") 30))
   (test-case "el control de case debe ser numero"
              (check-exn exn:fail?
                         (lambda () (corre "case true of 1 => 1 otherwise => 0 end"))))))


;;; ==========================================================
;;; Pruebas del grupo
;;; ==========================================================
;;; Cada función se prueba con aciertos y con errores. Los errores se
;;; comprueban con una expresión regular sobre el mensaje, para verificar
;;; que falla por la razón correcta y no por otra.

;; tokens-de : string -> lista
;; Los valores de los tokens de un texto, sin la clase ni la línea (la clase
;; de los literales la genera SLLGEN y no conviene escribirla en pruebas).
(define tokens-de
  (lambda (texto)
    (map cadr (scanner texto))))

;; clases-de : string -> lista de symbol
;; La clase de cada token que no es literal: identificador o numero.
(define clases-de
  (lambda (texto)
    (letrec ((solo-no-literales
              (lambda (tokens)
                (cond
                  ((null? tokens) '())
                  ((memq (car (car tokens)) '(identificador numero))
                   (cons (car (car tokens)) (solo-no-literales (cdr tokens))))
                  (else (solo-no-literales (cdr tokens)))))))
      (solo-no-literales (scanner texto)))))

(define analisis-lexico-y-sintactico
  (test-suite
   "Scanner y parser"
   (test-case "scanner: identificadores, numeros y signo"
              (check-equal? (tokens-de "x5 -7 3.5 -2.25") '(x5 -7 3.5 -2.25))
              (check-equal? (clases-de "x5 -7 3.5") '(identificador numero numero)))
   (test-case "scanner: los literales de la gramatica"
              (check-equal? (tokens-de "add1(x)") '("add1" "(" x ")"))
              (check-equal? (tokens-de "if true then 1 else 2 end")
                            '("if" "true" "then" 1 "else" 2 "end")))
   (test-case "scanner: espacios y comentarios no producen tokens"
              (check-equal? (tokens-de "// nada\n   42  // otro\n") '(42))
              (check-equal? (tokens-de "") '()))
   (test-case "scanner: el guion abre un numero negativo"
              (check-equal? (tokens-de "aplicar-n") '(aplicar "-" n))
              (check-equal? (tokens-de "-(5, 2)") '("-" "(" 5 "," 2 ")")))
   (test-case "scanner: identificadores con ? y guion bajo"
              (check-equal? (tokens-de "par? mi_var") '(par? mi_var)))
   (test-case "parser: literales y variables"
              (check-equal? (parser "42") (a-program (lit-exp 42)))
              (check-equal? (parser "n") (a-program (var-exp 'n)))
              (check-equal? (parser "true") (a-program (true-exp)))
              (check-equal? (parser "false") (a-program (false-exp))))
   (test-case "parser: primitivas"
              (check-equal? (parser "+(1, x)")
                            (a-program (prim-exp (sum-prim)
                                                 (list (lit-exp 1) (var-exp 'x)))))
              (check-equal? (parser "promedio(1, 2, 3)")
                            (a-program (prim-exp (promedio-prim)
                                                 (list (lit-exp 1) (lit-exp 2) (lit-exp 3))))))
   (test-case "parser: if y let"
              (check-equal? (parser "if true then 1 else 2 end")
                            (a-program (if-exp (true-exp) (lit-exp 1) (lit-exp 2))))
              (check-equal? (parser "let x = 1 y = 2 in x end")
                            (a-program (let-exp '(x y)
                                                (list (lit-exp 1) (lit-exp 2))
                                                (var-exp 'x)))))
   (test-case "parser: proc y apply"
              (check-equal? (parser "proc (a, b) a end")
                            (a-program (proc-exp '(a b) (var-exp 'a))))
              (check-equal? (parser "apply f (1, 2)")
                            (a-program (app-exp (var-exp 'f)
                                                (list (lit-exp 1) (lit-exp 2)))))
              (check-equal? (parser "proc () 1 end")
                            (a-program (proc-exp '() (lit-exp 1)))))
   (test-case "parser: letrec y case"
              (check-equal? (parser "letrec f (a) = a in apply f (1) end")
                            (a-program (letrec-exp '(f) '((a)) (list (var-exp 'a))
                                                   (app-exp (var-exp 'f) (list (lit-exp 1))))))
              (check-equal? (parser "case 1 of 1 => 2 of 3 => 4 otherwise => 0 end")
                            (a-program (case-exp (lit-exp 1) '(1 3)
                                                 (list (lit-exp 2) (lit-exp 4))
                                                 (lit-exp 0)))))
   (test-case "parser: un texto mal formado es un error"
              (check-exn #rx"." (lambda () (parser "if true then 1 end")))
              (check-exn #rx"." (lambda () (parser "let x = 1 in x")))
              (check-exn #rx"." (lambda () (parser "(apply f (3)) (4)"))))))

(define ambientes
  (test-suite
   "Ambiente y apply-env"
   (test-case "el ambiente inicial"
              (check-equal? (apply-env (ambiente-inicial) 'n) 10)
              (check-equal? (apply-env (ambiente-inicial) 'm) 3)
              (check-equal? (apply-env (ambiente-inicial) 'p) 7)
              (check-equal? (apply-env (ambiente-inicial) 'q) 2)
              (check-equal? (apply-env (ambiente-inicial) 'r) 5))
   (test-case "shadowing: la ligadura mas reciente gana"
              (let ((e (ambiente-extendido '(n) '(99) (ambiente-inicial))))
                (check-equal? (apply-env e 'n) 99)
                (check-equal? (apply-env e 'm) 3)))
   (test-case "dentro de un marco, la primera ligadura gana"
              (check-equal? (apply-env (ambiente-extendido '(x x) '(1 2) (ambiente-vacio)) 'x) 1))
   (test-case "una variable no ligada es un error"
              (check-exn #rx"no esta ligada" (lambda () (apply-env (ambiente-vacio) 'x)))
              (check-exn #rx"no esta ligada" (lambda () (apply-env (ambiente-inicial) 'zz))))
   (test-case "ambiente-recursivo: la clausura recibe el propio ambiente recursivo"
              (let* ((cuerpo (var-exp 'a))
                     (rec (ambiente-recursivo '(f g) '((a) (b c)) (list cuerpo cuerpo)
                                              (ambiente-inicial)))
                     (clausura (apply-env rec 'g)))
                (check-true (procval? clausura))
                (check-true (cases procval clausura
                              (cerradura (ids body env) (and (equal? ids '(b c)) (eq? env rec)))))
                (check-equal? (apply-env rec 'n) 10)))))

(define base-extra
  (test-suite
   "Parte 1 (adicional): aciertos y errores"
   (test-case "aritmetica con flotantes y negativos"
              (check-equal? (corre "+(1.5, 2.5)") 4.0)
              (check-equal? (corre "-(5)") 5)
              (check-equal? (corre "*(-2, 3)") -6)
              (check-equal? (corre "/(7, 2)") 7/2)
              (check-equal? (corre "+()") 0)
              (check-equal? (corre "*()") 1))
   (test-case "relacionales e igualdad"
              (check-equal? (corre ">(1, 2)") #f)
              (check-equal? (corre "<=(2, 2)") #t)
              (check-equal? (corre "==(1, 2)") #f)
              (check-equal? (corre "==(n, +(m, 7))") #t))
   (test-case "booleanos"
              (check-equal? (corre "not(false)") #t)
              (check-equal? (corre "or(false, false)") #f)
              (check-equal? (corre "and(true, true)") #t))
   (test-case "if elige solo una rama y no crea ambiente"
              (check-equal? (corre "if true then 1 else z end") 1)
              (check-equal? (corre "if false then z else 2 end") 2)
              (check-equal? (corre "if ==(n, 10) then if <(m, 1) then 1 else 2 end else 3 end") 2))
   (test-case "let: las ligaduras se evaluan en el ambiente de afuera"
              (check-equal? (corre "let n = 1 m = n in m end") 10)
              (check-equal? (corre "let x = +(n, 1) in let x = +(x, 2) in x end end") 13)
              (check-equal? (corre "let in 5 end") 5))
   (test-case "errores del lenguaje base"
              (check-exn #rx"booleana" (lambda () (corre "if +(1, 2) then 1 else 2 end")))
              (check-exn #rx"no esta ligada" (lambda () (corre "+(zz, 1)")))
              (check-exn #rx"no esta ligada" (lambda () (corre "let x = x in x end")))
              (check-exn #rx"Division por cero" (lambda () (corre "/(1, 0)")))
              (check-exn #rx"Division por cero" (lambda () (corre "/(8, 2, 0)")))
              (check-exn #rx"numero" (lambda () (corre "+(1, true)")))
              (check-exn #rx"booleano" (lambda () (corre "and(1, true)")))
              (check-exn #rx"booleano" (lambda () (corre "not(5)")))
              (check-exn #rx"exactamente 1" (lambda () (corre "add1(1, 2)")))
              (check-exn #rx"exactamente 2" (lambda () (corre "<(1)")))
              (check-exn #rx"al menos 1" (lambda () (corre "-()"))))))

(define primitivas-extra
  (test-suite
   "Parte 2 (adicional): aciertos y errores por primitiva"
   (test-case "abs"
              (check-equal? (corre "abs(0)") 0)
              (check-exn #rx"numero" (lambda () (corre "abs(false)")))
              (check-exn #rx"exactamente 1" (lambda () (corre "abs(1, 2)"))))
   (test-case "mcd"
              (check-equal? (corre "mcd(-12, 18)") 6)
              (check-equal? (corre "mcd(0, 5)") 5)
              (check-equal? (corre "mcd(100, 75, 50, 25)") 25)
              (check-exn #rx"al menos 2" (lambda () (corre "mcd(4)")))
              (check-exn #rx"entero" (lambda () (corre "mcd(4, 2.5)")))
              (check-exn #rx"entero" (lambda () (corre "mcd(true, 2)"))))
   (test-case "mcm"
              (check-equal? (corre "mcm(0, 5)") 0)
              (check-equal? (corre "mcm(-4, 6)") 12)
              (check-equal? (corre "mcm(1, 2, 3, 4, 5)") 60)
              (check-exn #rx"al menos 2" (lambda () (corre "mcm(4)")))
              (check-exn #rx"entero" (lambda () (corre "mcm(4, 1.5)"))))
   (test-case "promedio"
              (check-equal? (corre "promedio(1.5, 2.5)") 2.0)
              (check-equal? (corre "promedio(n, m, p)") 20/3)
              (check-equal? (corre "promedio(-2, 2)") 0)
              (check-exn #rx"al menos 1" (lambda () (corre "promedio()")))
              (check-exn #rx"numero" (lambda () (corre "promedio(1, true)"))))
   (test-case "xor"
              (check-equal? (corre "xor(false, true)") #t)
              (check-exn #rx"exactamente 2" (lambda () (corre "xor(true)")))
              (check-exn #rx"booleano" (lambda () (corre "xor(true, 0)"))))
   (test-case "implica"
              (check-equal? (corre "implica(false, true)") #t)
              (check-exn #rx"exactamente 2" (lambda () (corre "implica(true, true, true)")))
              (check-exn #rx"booleano" (lambda () (corre "implica(1, true)"))))
   (test-case "entre"
              (check-equal? (corre "entre(10, 1, 10)") #t)
              (check-equal? (corre "entre(0.5, 0, 1)") #t)
              (check-equal? (corre "entre(-1, 0, 1)") #f)
              (check-exn #rx"exactamente 3" (lambda () (corre "entre(1, 2, 3, 4)")))
              (check-exn #rx"numero" (lambda () (corre "entre(1, true, 3)"))))
   (test-case "evaluar-primitiva directamente"
              (check-equal? (evaluar-primitiva (sum-prim) '(1 2 3)) 6)
              (check-equal? (evaluar-primitiva (minus-prim) '(10 3 2)) 5)
              (check-equal? (evaluar-primitiva (and-prim) '(#t #f)) #f)
              (check-true (exigir-numeros '(1 2.5) 'x))
              (check-exn #rx"numero" (lambda () (exigir-numeros '(1 a) 'x)))
              (check-exn #rx"entero" (lambda () (exigir-enteros '(1 2.5) 'x)))
              (check-exn #rx"booleano" (lambda () (exigir-booleanos '(#t 1) 'x)))
              (check-true (exigir-cantidad '(1 2) 2 'x))
              (check-exn #rx"exactamente" (lambda () (exigir-cantidad '(1) 2 'x)))
              (check-true (exigir-minimo '(1 2 3) 2 'x))
              (check-exn #rx"al menos" (lambda () (exigir-minimo '(1) 2 'x))))))

(define procedimientos-extra
  (test-suite
   "Parte 3 (adicional): clausuras"
   (test-case "proc produce una clausura y no evalua el cuerpo"
              (check-true (procval? (corre "proc (x) x end")))
              (check-equal? (corre "let f = proc () zz end in 1 end") 1))
   (test-case "alcance estatico: la variable libre sale del ambiente de definicion"
              (check-equal? (corre "let x = 5 in let f = proc (y) +(x, y) end in let x = 28 in apply f (2) end end end") 7)
              (check-equal? (corre "let g = proc (u) +(q, u) end in let q = 100 in apply g (1) end end") 3))
   (test-case "un parametro tapa a la variable del ambiente"
              (check-equal? (corre "let f = proc (n) add1(n) end in apply f (1) end") 2)
              (check-equal? (corre "let f = proc (n) add1(n) end in +(n, apply f (1)) end") 12))
   (test-case "los argumentos se evaluan en el ambiente de la llamada"
              (check-equal? (corre "let f = proc (a) a end in let x = 7 in apply f (x) end end") 7))
   (test-case "procedimiento que recibe y retorna procedimientos"
              (check-equal? (corre "let g = proc (x) proc (y) proc (z) +(x, y, z) end end end
                                    in let a = apply g (1)
                                       in let b = apply a (2)
                                          in apply b (3) end
                                       end
                                    end") 6))
   (test-case "un procedimiento aplicado a su propio resultado"
              (check-equal? (corre "let inc = proc (x) add1(x) end in apply inc (apply inc (apply inc (0))) end") 3))
   (test-case "apply-procedure directamente"
              (let ((clausura (cerradura '(x y) (prim-exp (sum-prim) (list (var-exp 'x) (var-exp 'y)))
                                         (ambiente-inicial))))
                (check-equal? (apply-procedure clausura '(1 2)) 3)
                (check-exn #rx"espera 2 argumentos y recibio 1" (lambda () (apply-procedure clausura '(1))))
                (check-exn #rx"espera 2 argumentos y recibio 3" (lambda () (apply-procedure clausura '(1 2 3))))))
   (test-case "errores de la aplicacion"
              (check-exn #rx"no es un procedimiento" (lambda () (corre "apply 5 (1)")))
              (check-exn #rx"no es un procedimiento" (lambda () (corre "apply true ()")))
              (check-exn #rx"no es un procedimiento" (lambda () (corre "let x = 3 in apply x (1) end")))
              (check-exn #rx"espera 0 argumentos y recibio 1" (lambda () (corre "let f = proc () 1 end in apply f (2) end")))
              (check-exn #rx"espera 1 argumentos y recibio 0" (lambda () (corre "let f = proc (a) a end in apply f () end"))))))

(define recursion-y-case-extra
  (test-suite
   "Parte 4 (adicional): letrec y case"
   (test-case "letrec: fibonacci y suma"
              (check-equal? (corre "letrec fib (n) = if <(n, 2) then n else +(apply fib (sub1(n)), apply fib (-(n, 2))) end
                                    in apply fib (10) end") 55)
              (check-equal? (corre "letrec suma (n) = if ==(n, 0) then 0 else +(n, apply suma (sub1(n))) end
                                    in apply suma (4) end") 10))
   (test-case "letrec: tres procedimientos que se llaman entre si"
              (check-equal? (corre "letrec
                                      a (n) = if ==(n, 0) then 0 else apply b (sub1(n)) end
                                      b (n) = if ==(n, 0) then 1 else apply c (sub1(n)) end
                                      c (n) = if ==(n, 0) then 2 else apply a (sub1(n)) end
                                    in apply a (7) end") 1))
   (test-case "letrec: el procedimiento ve las variables del ambiente donde se declaro"
              (check-equal? (corre "letrec f (a) = +(a, n) in apply f (1) end") 11)
              (check-equal? (corre "let k = 5 in letrec f (a) = +(a, k) in apply f (1) end end") 6))
   (test-case "letrec: nombrar el procedimiento sin aplicarlo da una clausura"
              (check-true (procval? (corre "letrec doble (n) = *(n, 2) in doble end")))
              (check-equal? (corre "letrec doble (n) = *(n, 2) in 7 end") 7))
   (test-case "letrec: el cuerpo ve los procedimientos por el ambiente-recursivo"
              (check-equal? (corre "let f = proc (x) add1(x) end in letrec g (x) = apply f (x) in apply g (1) end end") 2))
   (test-case "con let la misma declaracion falla: el nombre no esta ligado en el cuerpo"
              (check-exn #rx"no esta ligada"
                         (lambda () (corre "let fact = proc (n) if ==(n, 0) then 1 else *(n, apply fact (sub1(n))) end end
                                            in apply fact (5) end")))
              (check-exn #rx"no esta ligada"
                         (lambda () (corre "letrec par (n) = if ==(n, 0) then 1 else apply impar (sub1(n)) end
                                            in letrec impar (n) = if ==(n, 0) then 0 else apply par (sub1(n)) end
                                               in apply par (7) end
                                            end"))))
   (test-case "letrec: un argumento de mas o de menos es un error"
              (check-exn #rx"espera 1 argumentos y recibio 2"
                         (lambda () (corre "letrec f (a) = a in apply f (1, 2) end"))))
   (test-case "case: la primera coincidencia gana"
              (check-equal? (corre "case 1 of 1 => 10 of 1 => 20 otherwise => 0 end") 10)
              (check-equal? (corre "case 7 of 1 => 100 of 3 => 300 of 7 => 700 otherwise => 0 end") 700))
   (test-case "case: otherwise cuando no hay coincidencia"
              (check-equal? (corre "case 9 of 1 => 100 otherwise => 0 end") 0)
              (check-equal? (corre "case 2 otherwise => 5 end") 5))
   (test-case "case: acepta flotantes y solo evalua la rama elegida"
              (check-equal? (corre "case 2.5 of 2.5 => 1 otherwise => 0 end") 1)
              (check-equal? (corre "case 1 of 1 => 10 of 2 => zz otherwise => zz end") 10))
   (test-case "case: el control puede ser cualquier expresion numerica"
              (check-equal? (corre "case *(n, m) of 30 => 1 otherwise => 0 end") 1)
              (check-equal? (corre "let f = proc (x) *(x, 2) end in case apply f (4) of 8 => 80 otherwise => 0 end end") 80))
   (test-case "case: control no numerico es un error"
              (check-exn #rx"debe ser un numero" (lambda () (corre "case true of 1 => 1 otherwise => 0 end")))
              (check-exn #rx"debe ser un numero" (lambda () (corre "case proc (x) x end of 1 => 1 otherwise => 0 end")))
              (check-exn #rx"no esta ligada" (lambda () (corre "case zz of 1 => 1 otherwise => 0 end"))))))

;; Las suites que agregue el grupo se declaran arriba y se suman aquí.

(define fallidas
  (+ (run-tests base)
     (run-tests primitivas-nuevas)
     (run-tests procedimientos)
     (run-tests recursion-y-case)
     (run-tests analisis-lexico-y-sintactico)
     (run-tests ambientes)
     (run-tests base-extra)
     (run-tests primitivas-extra)
     (run-tests procedimientos-extra)
     (run-tests recursion-y-case-extra)))

(eopl:printf "~%==========================================~%")
(eopl:printf "  pruebas fallidas en total: ~s~%" fallidas)
(eopl:printf "==========================================~%")