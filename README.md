Typesetter
==========

### Introduction

Typesetter is a factory extension for creating complex object sets, as a supplement to *factory_girl*, *fabrication*, or other factories.

It introduces the concept of **templates**: an abstract group of objects. These can be used to make test setup much quicker and easier.

For example, given:
```ruby
context "networkable people" do
  let(:phone_user) { create(:person, :devices => [phone]) }
  let(:phone) { create(:android, apps => [facebook_app_one, twitter_app_one]) } # Factory(:device)
  let(:facebook_phone) { create(:facebook, :platform => :phone) } # Factory(:app)
  let(:twitter_phone) { create(:twitter, :platform => :phone) } # Factory(:app)
  
  let(:tablet_user) { create(:person, :devices => [tablet]) }
  let(:tablet) { create(:tablet, apps => [facebook_tablet]) }  # Factory(:device) # Factory(:device)
  let(:facebook_tablet) { create(:facebook, :platform => :tablet) }  # Factory(:app)
  
  it { expect(phone_user.can_network_with(tablet_user).to be_true }
end
```

This is a lot of setup for a simple test case. We could write a bunch of named factories, but then the test logic simply ends up in a factory file rather than our test; not good.

Instead, we can use templates to make life easier:
```ruby
context "networkable people" do
  let(:phone_user) do |user|
    user.phone { |phone| phone.app :facebook }
  end
  let(:tablet_user) do |user|
    user.tablet { |tablet| tablet.app :facebook }
  end
  
  it { expect(phone_user.can_network_with(tablet_user).to be_true }
end
```
