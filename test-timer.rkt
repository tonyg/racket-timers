#lang racket/base

(require "main.rkt")

(define (drive-multiple name tm)
  (printf "MULTIPLE START ~a~n" name)
  (let loop ()
    (when (not (timer-manager-idle? tm))
      (printf "Syncing~n")
      (sync (fire-timers-evt tm))
      (loop)))
  (printf "MULTIPLE STOP  ~a~n" name))

(define (drive-single name tm)
  (printf "SINGLE START ~a~n" name)
  (let loop ()
    (when (not (timer-manager-idle? tm))
      (printf "Syncing~n")
      (sync (fire-single-timer-evt tm
				   (lambda (v)
				     (printf "(yielded ~a)~n" v)
				     (loop))
				   (lambda ()
				     (printf "(skipped)~n")
				     (loop))))))
  (printf "SINGLE STOP  ~a~n" name))

(define (test-multiple-firing driver)
  (define tm (make-timer-manager))
  (add-relative-timer! tm 200 (lambda () (printf "t3~n") 3))
  (add-relative-timer! tm 200 (lambda () (printf "t2~n") 2))
  (add-relative-timer! tm 100 (lambda () (printf "t1~n") (sleep 0.2) 1))
  (driver 'test-multiple-firing tm))

(define (test-cancellation driver)
  (define tm (make-timer-manager))
  (add-relative-timer! tm 300 (lambda () (printf "t3~n") 3))
  (define t2 (add-relative-timer! tm 200 (lambda () (printf "t2~n") 2)))
  (add-relative-timer! tm 100 (lambda () (cancel-timer! t2) (printf "t1~n") 1))
  (driver 'test-cancellation tm))

(module+ main
  (test-multiple-firing drive-multiple)
  (test-cancellation drive-multiple)
  (test-multiple-firing drive-single)
  (test-cancellation drive-single))
