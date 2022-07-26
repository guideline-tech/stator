# frozen_string_literal: true

module Stator
  MAJOR       = 0
  MINOR       = 9
  PATCH       = 0
  PRERELEASE  = "beta"

  VERSION = [MAJOR, MINOR, PATCH, PRERELEASE].compact.join('.')
end
