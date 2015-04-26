;;;
;;; Beware of browser caching when trying this example
;;;

(use awful spiffy spiffy-antiscam uri-common)

(enable-sxml #t)

(default-scam-response-file "/scam.png")

(define scammers-blacklist
  (list
   ;; string matcher
   "http://localhost:8080/scam"

   ;; regex matcher
   (irregex "http://localhost:8080/the-scammer[0-9]")

   ;; procedure matcher (receives an uri object)
   (lambda (uri)
     (let ((path (uri-path uri)))
       (and (not (null? (cdr path)))
            (equal? (cadr path) "scammer"))))))

(vhost-map
 `((".*" . ,(lambda (continue)
              ;; Will send /scam.png instead of /some-img.png if the
              ;; referer matches any item in scammers-blacklist
              (antiscam "/some-img.png" scammers-blacklist)
              (continue)))))

(define (handler)
  `(img (@ (src "http://localhost:8080/some-img.png"))))

(define-page "/scam" handler)
(define-page "/the-scammer1" handler)
(define-page "/scammer/pro" handler)
(define-page "/not-scam" handler)
