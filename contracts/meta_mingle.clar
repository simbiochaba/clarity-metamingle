;; MetaMingle Smart Contract
(define-non-fungible-token profile principal)
(define-fungible-token virtual-gift)

;; Data Variables
(define-map user-profiles
    principal
    {
        name: (string-ascii 64),
        bio: (string-ascii 256), 
        age: uint,
        interests: (list 10 (string-ascii 32)),
        active: bool,
        tokens: uint
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

(define-map virtual-gifts
    uint 
    {
        name: (string-ascii 32),
        description: (string-ascii 128),
        price: uint,
        creator: principal
    }
)

(define-map user-matches
    principal
    (list 50 {
        match: principal,
        score: uint,
        shared-interests: (list 10 (string-ascii 32))
    })
)

;; Constants
(define-constant contract-owner tx-sender)
(define-data-var next-date-id uint u0)
(define-data-var next-gift-id uint u0)

;; Error constants  
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-already-exists (err u409))
(define-constant err-insufficient-funds (err u402))

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
            active: true,
            tokens: u100
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

;; Virtual Gift System
(define-public (create-gift (name (string-ascii 32)) (description (string-ascii 128)) (price uint))
    (let (
        (gift-id (var-get next-gift-id))
        (caller tx-sender)
    )
        (map-set virtual-gifts gift-id {
            name: name,
            description: description,
            price: price,
            creator: caller
        })
        (var-set next-gift-id (+ gift-id u1))
        (ok gift-id)
    )
)

(define-public (send-gift (gift-id uint) (to principal))
    (let (
        (caller tx-sender)
        (gift (unwrap! (map-get? virtual-gifts gift-id) err-not-found))
        (sender-profile (unwrap! (map-get? user-profiles caller) err-not-found))
    )
        (asserts! (>= (get tokens sender-profile) (get price gift)) err-insufficient-funds)
        (try! (ft-mint? virtual-gift (get price gift) to))
        (ok (map-set user-profiles caller {
            name: (get name sender-profile),
            bio: (get bio sender-profile),
            age: (get age sender-profile),
            interests: (get interests sender-profile),
            active: (get active sender-profile),
            tokens: (- (get tokens sender-profile) (get price gift))
        }))
    )
)

;; Matchmaking System
(define-public (generate-matches (user principal))
    (let ((user-profile (unwrap! (map-get? user-profiles user) err-not-found)))
        (ok (calculate-matches user user-profile))
    )
)

(define-private (calculate-matches (user principal) (profile {name: (string-ascii 64), bio: (string-ascii 256), age: uint, interests: (list 10 (string-ascii 32)), active: bool, tokens: uint}))
    (map-set user-matches user 
        (filter matches-filter 
            (map unwrap-profile 
                (get-all-profiles))))
    true
)

;; Read-only functions
(define-read-only (get-profile (user principal))
    (ok (map-get? user-profiles user))
)

(define-read-only (get-date-details (date-id uint))
    (ok (map-get? virtual-dates date-id))
)

(define-read-only (get-gift-details (gift-id uint))
    (ok (map-get? virtual-gifts gift-id))
)

(define-read-only (get-matches (user principal))
    (ok (map-get? user-matches user))
)
