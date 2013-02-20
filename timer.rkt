#lang racket/base
;; Timer management.

(require racket/set)
(require racket/match)
(require data/heap)

(provide (struct-out pending-timer)
	 (except-out (struct-out timer-manager) timer-manager)
	 (rename-out [real-make-timer-manager make-timer-manager])

	 timer-evt

	 timer-manager-idle?

	 add-absolute-timer!
	 add-relative-timer!

	 fire-single-timer-evt
	 fire-single-timer

	 fire-timers-evt
	 fire-timers

	 cancel-timer!)

(struct timer-manager (heap) #:transparent)

(struct pending-timer (deadline handler [cancelled? #:mutable]) #:transparent)

;; Racket's alarm-evt is almost the right design for timeouts: its
;; synchronisation value should be the (or some) value of the clock
;; after the asked-for time. That way it serves as timeout and
;; clock-reader in one.
(define (timer-evt msecs)
  (wrap-evt (alarm-evt msecs)
	    (lambda (_) (current-inexact-milliseconds))))

(define (timer-manager-idle? tm)
  (heap-empty? (timer-manager-heap tm)))

(define (pending-timer<=? a b)
  (<= (pending-timer-deadline a)
      (pending-timer-deadline b)))

(define (real-make-timer-manager)
  (timer-manager (make-heap pending-timer<=?)))

(define (add-absolute-timer! tm s h)
  (define new-timer (pending-timer s h #f))
  (heap-add! (timer-manager-heap tm) new-timer)
  new-timer)

(define (add-relative-timer! tm delta-s h)
  (add-absolute-timer! tm (+ (current-inexact-milliseconds) delta-s) h))

(define (heap-empty? h)
  (zero? (heap-count h)))

(define (wait-for-timer-evt tm k)
  (define h (timer-manager-heap tm))
  (if (heap-empty? h)
      never-evt
      (handle-evt (alarm-evt (pending-timer-deadline (heap-min h)))
		  (lambda (_) (k)))))

(define (fire-single-timer-evt tm k-fired k-not-fired)
  (wait-for-timer-evt tm (lambda () (fire-single-timer tm k-fired k-not-fired))))

(define (fire-single-timer tm k-fired k-not-fired)
  (define h (timer-manager-heap tm))
  (define now (current-inexact-milliseconds))
  (if (heap-empty? h)
      (k-not-fired)
      (let ((t (heap-min h)))
	(if (< now (pending-timer-deadline t))
	    (k-not-fired)
	    (begin (heap-remove-min! h)
		   (if (pending-timer-cancelled? t)
		       (k-not-fired)
		       (call-with-values (pending-timer-handler t) k-fired)))))))

(define (fire-timers-evt tm)
  (wait-for-timer-evt tm (lambda () (fire-timers tm))))

(define (fire-timers tm)
  (define h (timer-manager-heap tm))
  (define now (current-inexact-milliseconds))
  (let loop ()
    (when (not (heap-empty? h))
      (define t (heap-min h))
      (when (>= now (pending-timer-deadline t))
	(heap-remove-min! h)
	(when (not (pending-timer-cancelled? t))
	  ((pending-timer-handler t)))
	(loop)))))

(define (cancel-timer! t)
  (set-pending-timer-cancelled?! t #t))
