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
        tokens: uint,
        last-active: uint
    }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-age u18)
(define-constant max-age u100)
(define-constant initial-tokens u100)

;; Error constants  
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-already-exists (err u409))
(define-constant err-insufficient-funds (err u402))
(define-constant err-invalid-age (err u403))
(define-constant err-inactive-profile (err u405))

;; Profile Management
(define-public (create-profile (name (string-ascii 64)) (bio (string-ascii 256)) (age uint) (interests (list 10 (string-ascii 32))))
    (let ((caller tx-sender))
        (asserts! (not (is-some (map-get? user-profiles caller))) err-already-exists)
        (asserts! (and (>= age min-age) (<= age max-age)) err-invalid-age)
        (try! (nft-mint? profile caller caller))
        (ok (map-set user-profiles caller {
            name: name,
            bio: bio,
            age: age,
            interests: interests,
            active: true,
            tokens: initial-tokens,
            last-active: block-height
        }))
    )
)

(define-public (deactivate-profile)
    (let ((caller tx-sender)
          (profile (unwrap! (map-get? user-profiles caller) err-not-found)))
        (ok (map-set user-profiles caller (merge profile {active: false})))
    )
)

;; Enhanced Connection System
(define-public (respond-to-connection (from principal) (accept bool))
    (let ((request (unwrap! (map-get? connection-requests {from: from, to: tx-sender}) err-not-found)))
        (asserts! (is-eq (get status request) "pending") err-unauthorized)
        (ok (map-set connection-requests {from: from, to: tx-sender}
            {
                status: (if accept "accepted" "rejected"),
                timestamp: block-height
            }))
    )
)

;; Enhanced Matchmaking System
(define-private (calculate-match-score (user-a principal) (user-b principal))
    (let ((profile-a (unwrap! (map-get? user-profiles user-a) u0))
          (profile-b (unwrap! (map-get? user-profiles user-b) u0)))
        (let ((age-diff (abs (- (get age profile-a) (get age profile-b))))
              (shared-interests (len (filter is-shared-interest (get interests profile-a)))))
            (+ (* u2 shared-interests)
               (if (<= age-diff u5) u10 u0))
        )
    )
)

;; Helper Functions
(define-private (is-shared-interest (interest (string-ascii 32)))
    (is-some (index-of interest (get interests profile-b)))
)

(define-private (abs (n int))
    (if (< n 0) (* n -1) n)
)

[... rest of the original contract with enhanced security checks ...]
