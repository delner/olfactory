Typesetter
==========

### Introduction

Typesetter is a factory extension for creating complex object sets, as a supplement to *factory_girl*, *fabrication*, or other factories.

It introduces the concept of **templates**: an abstract group of objects. These can be used to make test setup much quicker and easier.

Templates are not intended to replace most factories. They are most useful when:
 - Subjects are weakly related or non-relational (e.g. not joined by ActiveRecord associations)
 - You require a collection of objects that are not directly related (or easily built using factories)
 - You'd prefer short-hand notation, or to abstract Factory implementation out of your tests
   - e.g. Define a set of generic factories other programmers can use, without requiring them to understand the underlying details

For example, given:
```ruby
context "networkable people" do
  let(:phone_user) { create(:person, :devices => [phone]) }
  let(:phone) { create(:android, apps => [facebook_app_one, twitter_app_one]) } # Factory(:device)
  let(:facebook_phone) { create(:facebook, :platform => :phone) } # Factory(:app)
  let(:twitter_phone) { create(:twitter, :platform => :phone) } # Factory(:app)
  
  let(:tablet_user) { create(:person, :devices => [tablet]) }
  let(:tablet) { create(:tablet, apps => [facebook_tablet]) }  # Factory(:device)
  let(:facebook_tablet) { create(:facebook, :platform => :tablet) }  # Factory(:app)
  
  let(:desktop_user) { create(:person, :devices => [desktop]) }
  let(:desktop) { create(:desktop, apps => [twitter_desktop]) }  # Factory(:device)
  let(:twitter_desktop) { create(:twitter, :platform => :desktop) }  # Factory(:app)
  
  it { expect(phone_user.can_network_with(tablet_user, desktop_user).to be_true }
end
```

This is a lot of setup for a simple test case. We could write a bunch of named factories, but then the test logic simply ends up in a factory file rather than our test; not good.

Instead, we can use templates to simplify our definitions:
```ruby
context "networkable people" do
  let(:user_group) do
    Typesetter.create_template :user_group do |group|
      group.user :desktop_user { |user| user.phone { |phone| phone.app :facebook, :twitter } }
      group.user :tablet_user { |user| user.tablet { |tablet| tablet.app :facebook } }
      group.user :phone_user { |user| user.desktop { |desktop| desktop.app :twitter } }
    end
  end
  
  it { expect(user_group[:desktop_user].can_network_with(user_group[:tablet_user], user_group[:phone_user]).to be_true }
end
```
