# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{external_resque_worker}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Gordon", "Joel Meador", "Chris Moore", "Jason Gladish"]
  s.date = %q{2012-01-04}
  s.description = %q{Easy way to manage running one or more resque processes during testing}
  s.email = %q{matt@expectedbehavior.com joel@expectedbehavior.com jason@expectedbehavior.com chris@monoclesoftware.com}
  s.homepage = %q{http://expectedbehavior.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Easy way to manage running one or more resque processes during testing}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
