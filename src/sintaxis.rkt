#lang eopl
;Autores: Luis David Mendoza Manzano - 2067621

;; Taller 2 — El intérprete de Cauca.
;; Especificación léxica, especificación gramatical, scanner y parser.
;; Este módulo no requiere ningún otro.
;;
;; Lo que se escribe aquí:
;;
;;   especificacion-lexica      comentarios que empiezan con //, espacios
;;                              en blanco, números enteros y flotantes con
;;                              signo, e identificadores que empiezan por
;;                              letra y siguen con letras, dígitos, guion
;;                              bajo o signo de interrogación
;;   especificacion-gramatical  las producciones de <programa>,
;;                              <expresion> y <primitiva>, con los nombres
;;                              de constructor que indican los recuadros
;;                              del enunciado
;;   scanner : string -> lista de tokens   se construye con
;;                                         sllgen:make-string-scanner
;;   parser  : string -> programa          se construye con
;;                                         sllgen:make-string-parser
;;
;; La llamada a sllgen:make-define-datatypes genera los datatypes
;; programa, expresion y primitiva a partir de la gramática, con sus
;; constructores y sus predicados.

;; especificacion-lexica : lista de reglas léxicas
;; Cada regla lleva nombre, expresión regular y acción. Los espacios y los
;; comentarios se descartan (skip). El guion abre un número negativo, así
;; que un identificador no puede llevarlo: aplicar-n se lee como el
;; identificador aplicar seguido del número -n.
(define especificacion-lexica
  '((espacio-blanco (whitespace) skip)
    (comentario ("//" (arbno (not #\newline))) skip)
    (identificador (letter (arbno (or letter digit "_" "?"))) symbol)
    (numero (digit (arbno digit)) number)
    (numero ("-" digit (arbno digit)) number)
    (numero (digit (arbno digit) "." digit (arbno digit)) number)
    (numero ("-" digit (arbno digit) "." digit (arbno digit)) number)))

;; especificacion-gramatical : lista de producciones
;; La gramática base más las ampliaciones de las Partes 2, 3 y 4. Cada
;; producción termina con el nombre del constructor del AST. La palabra
;; end cierra if, let, proc, letrec y case; la palabra apply abre la
;; aplicación, para que SLLGEN decida con un solo token de anticipación.
(define especificacion-gramatical
  '((programa (expresion) a-program)

    (expresion (numero) lit-exp)
    (expresion (identificador) var-exp)
    (expresion ("true") true-exp)
    (expresion ("false") false-exp)
    (expresion (primitiva "(" (separated-list expresion ",") ")") prim-exp)
    (expresion ("if" expresion "then" expresion "else" expresion "end")
               if-exp)
    (expresion ("let" (arbno identificador "=" expresion) "in" expresion "end")
               let-exp)
    (expresion ("proc" "(" (separated-list identificador ",") ")" expresion "end")
               proc-exp)
    (expresion ("apply" expresion "(" (separated-list expresion ",") ")")
               app-exp)
    (expresion ("letrec"
                (arbno identificador
                       "(" (separated-list identificador ",") ")"
                       "=" expresion)
                "in" expresion "end")
               letrec-exp)
    (expresion ("case" expresion
                (arbno "of" numero "=>" expresion)
                "otherwise" "=>" expresion "end")
               case-exp)

    (primitiva ("+") sum-prim)
    (primitiva ("-") minus-prim)
    (primitiva ("*") mult-prim)
    (primitiva ("/") div-prim)
    (primitiva ("add1") add-prim)
    (primitiva ("sub1") sub-prim)
    (primitiva (">") mayor-prim)
    (primitiva (">=") mayorigual-prim)
    (primitiva ("<") menor-prim)
    (primitiva ("<=") menorigual-prim)
    (primitiva ("==") igual-prim)
    (primitiva ("not") not-prim)
    (primitiva ("and") and-prim)
    (primitiva ("or") or-prim)
    (primitiva ("abs") abs-prim)
    (primitiva ("mcd") mcd-prim)
    (primitiva ("mcm") mcm-prim)
    (primitiva ("promedio") promedio-prim)
    (primitiva ("xor") xor-prim)
    (primitiva ("implica") implica-prim)
    (primitiva ("entre") entre-prim)))

(sllgen:make-define-datatypes especificacion-lexica especificacion-gramatical)

;; mostrar-datatypes : -> void
;; Lista en pantalla los datatypes que SLLGEN genera a partir de la
;; gramática. Sirve para revisar los nombres de los constructores.
(define mostrar-datatypes
  (lambda ()
    (sllgen:list-define-datatypes especificacion-lexica especificacion-gramatical)))

;; analizador-lexico : string -> lista de tokens
;; El scanner que construye SLLGEN a partir de las dos especificaciones.
(define analizador-lexico
  (sllgen:make-string-scanner especificacion-lexica especificacion-gramatical))

;; analizador-sintactico : string -> programa
;; El parser que construye SLLGEN a partir de las dos especificaciones.
(define analizador-sintactico
  (sllgen:make-string-parser especificacion-lexica especificacion-gramatical))

;; scanner : string -> lista de tokens
;; Convierte el texto de un programa en la lista de sus tokens. Descarta
;; los espacios y los comentarios.
;; Ejemplo: (scanner "add1(x)") => lista con add1, "(", x y ")".
(define scanner
  (lambda (texto)
    (analizador-lexico texto)))

;; parser : string -> programa
;; Convierte el texto de un programa en su árbol de sintaxis abstracta.
;; Ejemplo: (parser "42") => (a-program (lit-exp 42))
(define parser
  (lambda (texto)
    (analizador-sintactico texto)))

(provide (all-defined-out))