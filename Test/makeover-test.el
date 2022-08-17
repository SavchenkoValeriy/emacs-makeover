;; -*- lexical-binding: t; -*-

(ert-deftest makeover:swift-tests ()
  (message "HERE")
  (should-not (makeover:run-swift-tests)))
