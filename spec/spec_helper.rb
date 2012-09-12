# Conditional Spork.prefork (this comment is needed to fool Spork's `bootstrapped?` check)
helper_kind = /spork/i =~ $0 || RSpec.configuration.drb?  ? "spork" : "base"
require File.expand_path("../spec_helper_#{helper_kind}", __FILE__)
