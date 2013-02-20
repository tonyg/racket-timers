#lang scribble/manual

@(require planet/scribble
	  scribble/racket
	  scriblib/footnote
	  (for-label racket
	  	     data/heap
	  	     (this-package-in main)))

@title{racket-timers}
@author[(author+email "Tony Garnock-Jones" "tonygarnockjones@gmail.com")]

@local-table-of-contents[]

If you find that this library lacks some feature you need, or you have
a suggestion for improving it, please don't hesitate to
@link["mailto:tonygarnockjones@gmail.com"]{get in touch with me}!

@section{Introduction}

This library provides utilities for managing a heap of timeouts when
programming in an event-driven style with @racket[sync].

@section{What to require}

All the functionality below can be accessed with a single
@racket[require]:

@(defmodule/this-package main)

@subsection{Raw timeout events}

@defproc[(timer-evt [msecs nonnegative-number?]) evt?]{
Just like @racket[alarm-evt], but yields as its value the value of
@racket[current-inexact-milliseconds] at (or shortly after) the time
the event fires. This contrasts with @racket[alarm-evt] in that
@racket[alarm-evt] yields no useful value.}

@subsection{Timers and timer managers}

@defproc[(make-timer-manager) timer-manager?]{
Construct a fresh timer-manager with an empty internal queue of timers.}

@defproc[(add-absolute-timer! [tm timer-manager?]
			      [deadline nonnegative-number?]
			      [handler (-> any?)]) pending-timer?]{
Registers a new timer with the given timer-manager, that will expire
at the given deadline (N.B.: milliseconds! Use
@racket[current-inexact-milliseconds]), calling the given handler
callback. The timer descriptor is returned (for potential later use
with @racket[cancel-timer!]).}

@defproc[(add-relative-timer! [tm timer-manager?]
			      [delta-msec number?]
			      [handler (-> any?)]) pending-timer?]{
As @racket[add-absolute-timer!], but instead of expecting an absolute
expiry deadline, takes an expiry time expressed as a number of
milliseconds relative to the value of
@racket[current-inexact-milliseconds] at the time of the call.}

@defproc[(fire-single-timer-evt [tm timer-manager?]
				[k-fired (->* () #:rest any? any?)]
				[k-not-fired (-> any?)]) evt?]{
Returns an event for use with @racket[sync] that is ready to fire only
when @racket[current-inexact-milliseconds] is past the earliest event
in the queue managed by @racket[tm]. If selected, tail-calls
@racket[fire-single-timer] (with the same arguments as it was given
itself) to produce the values to yield from the event.}

@defproc[(fire-single-timer [tm timer-manager?]
			    [k-fired (->* () #:rest any? any?)]
			    [k-not-fired (-> any?)]) any?]{
Checks the queue of timers in @racket[tm]. If none are ready to fire,
tail-calls @racket[k-not-fired]. Otherwise, selects the first ready
timer in the queue. If it has been cancelled, tail-calls
@racket[k-not-fired]. Otherwise, tail-calls @racket[k-fired] with the
values returned from its handler callback.}

@defproc[(fire-timers-evt [tm timer-manager?]) evt?]{
Returns an event for use with @racket[sync] that is ready to fire only
when @racket[current-inexact-milliseconds] is past the earliest event
in the queue managed by @racket[tm]. If selected, tail-calls
@racket[fire-timers], yielding @racket[(void)].}

@defproc[(fire-timers [tm timer-manager?]) void?]{
Checks the queue of timers in @racket[tm], calling handlers for
expired timers (ignoring the results from the handlers) and removing
them from the queue until no further expired timers remain to be
processed.}

@defproc[(cancel-timer! [t pending-timer?]) void?]{
Cancels an outstanding timer. If the timer's handler has not been
called at the time @racket[cancel-timer!] is called, then the timer's
handler will not ever be called by any of the functions or events
provided by this module.}

@defstruct[timer-manager ([heap heap?]) #:transparent]{
Represents a collection of pending timers. Updated by in-place
mutation. Note that no access to the raw constructor of this struct is
provided.}

@defstruct[pending-timer ([deadline nonnegative-number?]
			  [handler (-> any?)]
			  [cancelled? boolean?]) #:transparent]{
A record of a timer registered with some timer manager.

@racket[pending-timer-deadline] is the value of
@racket[current-inexact-milliseconds] after which the event will
fire (when the pending timer's timer-manager is checked for expired
events).

@racket[pending-timer-handler] is the timer callback. It will be
called with no arguments, and may yield any number of values. The
values are ignored if either @racket[fire-timers] or
@racket[fire-timers-evt] is used to trigger the firing of the timer,
and are used if either @racket[fire-single-timer] or
@racket[fire-single-timer-evt] fire the timer.

@racket[pending-timer-cancelled?] indicates whether this timer has
been cancelled. A cancelled timer's callback will never be called; it
is as if it were never registered.}

@defproc[(timer-manager-idle? [tm timer-manager?]) boolean?]{
Returns @racket[#t] if and only if there are no queued timers on the
given timer manager; otherwise, returns @racket[#f]. Note that even a
single cancelled timer that has not yet been cleared (via one of the
event-firing routines above) will cause this procedure to return
@racket[#t].}
