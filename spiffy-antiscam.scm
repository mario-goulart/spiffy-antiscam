(module spiffy-antiscam

(antiscam match-scam default-scam-response-file)

(import chicken scheme)
(use data-structures files irregex)
(use intarweb spiffy uri-common)

;; Utils

(define (uri-path->string uri)
  (let ((path (uri-path uri)))
    (if (eq? (car path) '/)
        (string-append "/" (string-intersperse (cdr path) "/"))
        (string-intersperse (cdr path) "/"))))


;; Low level interface

(define match-scam
  (make-parameter
   (lambda (path referer-uri)
     #f)))

(define (basic-antiscam path)
  (and-let* ((referer
              (header-value 'referer (request-headers (current-request)))))
    ((match-scam) path referer)))


;; High level interface

(define default-scam-response-file
  ;; File to be sent to scammers instead of the requested one
  (make-parameter "/scam-response.png"))

(define (simple-antiscam path scam-matchers)
  (parameterize
      ((match-scam
        (lambda (path referer-uri)
          (let* ((requested-path
                  (uri-path->string (request-uri (current-request))))
                 (referer-uri-obj referer-uri)
                 (referer-uri (uri->string referer-uri-obj)))
            (and (equal? requested-path path)
                 (let loop ((matchers scam-matchers))
                   (if (null? matchers)
                       #f
                       (let ((matcher (car matchers)))
                         (or (cond ((string? matcher)
                                    (equal? matcher referer-uri))
                                   ((irregex? matcher)
                                    (irregex-match matcher referer-uri))
                                   ((procedure? matcher)
                                    (and referer-uri
                                         (matcher referer-uri-obj)))
                                   (else (error 'simple-antiscam
                                                "Unknown object"
                                                matcher)))
                             (loop (cdr matchers)))))))))))
    (and (basic-antiscam path)
         (default-scam-response-file)
         (let ((response-file-dir
                (make-pathname (root-path)
                               (pathname-directory
                                (default-scam-response-file)))))
           (parameterize ((root-path response-file-dir))
             (send-static-file
              (pathname-strip-directory
               (default-scam-response-file))))))))


;; Wrapper

(define (antiscam path #!optional scam-matchers)
  (if scam-matchers
      (simple-antiscam path scam-matchers)
      (basic-antiscam path)))

) ;; end module
