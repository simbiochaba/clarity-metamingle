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
        last-active: uint,
        privacy-level: uint,
        verified: bool
    }
)

;; Rate Limiting Map
(define-map request-counts
    principal
    {
        count: uint,
        last-reset: uint
    }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-age u18)
(define-constant max-age u100)
(define-constant initial-tokens u100)
(define-constant max-daily-requests u10)
(define-constant blocks-per-day u144)
(define-constant privacy-public u1)
(define-constant privacy-friends u2)
(define-constant privacy-private u3)

;; Error constants  
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-already-exists (err u409))
(define-constant err-insufficient-funds (err u402))
(define-constant err-invalid-age (err u403))
(define-constant err-inactive-profile (err u405))
(define-constant err-rate-limited (err u429))

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
            last-active: block-height,
            privacy-level: privacy-public,
            verified: false
        }))
    )
)

;; Enhanced Matchmaking System
(define-private (calculate-match-score (user-a principal) (user-b principal))
    (let ((profile-a (unwrap! (map-get? user-profiles user-a) u0))
          (profile-b (unwrap! (map-get? user-profiles user-b) u0)))
        (let ((age-diff (abs (- (get age profile-a) (get age profile-b))))
              (shared-interests (len (filter is-shared-interest (get interests profile-a))))
              (activity-score (calculate-activity-score profile-b)))
            (+ (* u3 shared-interests)
               (if (<= age-diff u5) u15 u0)
               activity-score)
        )
    )
)

(define-private (calculate-activity-score (profile {active: bool, last-active: uint}))
    (if (get active profile)
        (let ((blocks-since-active (- block-height (get last-active profile))))
            (if (< blocks-since-active blocks-per-day)
                u10
                (if (< blocks-since-active (* u7 blocks-per-day))
                    u5
                    u0)))
        u0)
)

;; Rate Limiting
(define-private (check-rate-limit (user principal))
    (let ((current-count (default-to {count: u0, last-reset: u0} 
                                   (map-get? request-counts user))))
        (if (> (- block-height (get last-reset current-count)) blocks-per-day)
            (map-set request-counts user {count: u1, last-reset: block-height})
            (if (< (get count current-count) max-daily-requests)
                (map-set request-counts user 
                    {count: (+ (get count current-count) u1), 
                     last-reset: (get last-reset current-count)})
                false))
    )
)

;; Privacy Settings
(define-public (update-privacy-level (level uint))
    (let ((caller tx-sender)
          (profile (unwrap! (map-get? user-profiles caller) err-not-found)))
        (asserts! (or (is-eq level privacy-public)
                    (is-eq level privacy-friends)
                    (is-eq level privacy-private)) err-unauthorized)
        (ok (map-set user-profiles caller (merge profile {privacy-level: level})))
    )
)
