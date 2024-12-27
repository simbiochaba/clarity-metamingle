;; MetaMingle Smart Contract
(define-non-fungible-token profile principal)

;; Data Variables
(define-map user-profiles
    principal
    {
        name: (string-ascii 64),
        bio: (string-ascii 256),
        age: uint,
        interests: (list 10 (string-ascii 32)),
        active: bool
    }
)

(define-map connection-requests
    {
        from: principal,
        to: principal
    }
    {
        status: (string-ascii 20),
        timestamp: uint
    }
)

(define-map virtual-dates
    uint
    {
        creator: principal,
        participant: principal,
        time: uint,
        status: (string-ascii 20),
        location: (string-ascii 64)
    }
)

(define-map date-reviews
    uint
    {
        reviewer: principal,
        reviewed: principal,
        rating: uint,
        comment: (string-ascii 256)
    }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-data-var next-date-id uint u0)

;; Error constants
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-already-exists (err u409))

;; Profile Management
(define-public (create-profile (name (string-ascii 64)) (bio (string-ascii 256)) (age uint) (interests (list 10 (string-ascii 32))))
    (let ((caller tx-sender))
        (asserts! (not (is-some (map-get? user-profiles caller))) err-already-exists)
        (try! (nft-mint? profile caller caller))
        (ok (map-set user-profiles caller {
            name: name,
            bio: bio,
            age: age,
            interests: interests,
            active: true
        }))
    )
)

;; Connection System
(define-public (send-connection-request (to principal))
    (let ((from tx-sender))
        (asserts! (not (is-eq from to)) (err u400))
        (ok (map-set connection-requests {from: from, to: to} 
            {
                status: "pending",
                timestamp: block-height
            }))
    )
)

;; Virtual Date Management
(define-public (schedule-date (with principal) (time uint) (location (string-ascii 64)))
    (let (
        (date-id (var-get next-date-id))
        (caller tx-sender)
    )
        (asserts! (not (is-eq caller with)) (err u400))
        (map-set virtual-dates date-id {
            creator: caller,
            participant: with,
            time: time,
            status: "scheduled",
            location: location
        })
        (var-set next-date-id (+ date-id u1))
        (ok date-id)
    )
)

;; Review System
(define-public (submit-review (date-id uint) (reviewed principal) (rating uint) (comment (string-ascii 256)))
    (let ((reviewer tx-sender))
        (asserts! (<= rating u5) (err u400))
        (ok (map-set date-reviews date-id {
            reviewer: reviewer,
            reviewed: reviewed,
            rating: rating,
            comment: comment
        }))
    )
)

;; Read-only functions
(define-read-only (get-profile (user principal))
    (ok (map-get? user-profiles user))
)

(define-read-only (get-date-details (date-id uint))
    (ok (map-get? virtual-dates date-id))
)