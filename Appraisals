# Rails <= 5.2 is not compatible with Ruby > 2.7
if Gem::Version.new(RUBY_VERSION) <= Gem::Version.new("2.7")
  appraise "activerecord-5.1" do
    gem "activerecord", "~> 5.1.0"
  end

  appraise "activerecord-5.2" do
    gem "activerecord", "~> 5.2.0"
  end
end

appraise "activerecord-6.0" do
  gem "activerecord", "~> 6.0.0"
end

appraise "activerecord-6.1" do
  gem "activerecord", "~> 6.1.0"
end

appraise "activerecord-7.0" do
  gem "activerecord", "~> 7.0.0"
end
