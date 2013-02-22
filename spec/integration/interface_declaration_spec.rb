require 'spec_helper'
require 'accord'

describe "Accord::Interface method" do
  let(:mod) { Module.new }
  let(:not_constant) do
    Accord::Interface(:NotConstant) do
      responds_to :method
    end
  end

  before do
    stub_const('TestModule', mod)

    Accord::Interface(TestModule, :Base) do
      responds_to :method1

      invariant :invariant do |ob, errors|
        ob.base_invariant_ran
        errors << :base if ob.set_error
        :ignore_return
      end

      tags[:tag] = :base
      interface[:method1].tags[:tag] = :value
    end

    Accord::Interface(TestModule, :Extension) do
      extends TestModule::Base

      responds_to :method2, params: [{ param: :default }]

      invariant :invariant do |ob, errors|
        ob.extension_invariant_ran
        errors << :extension if ob.set_error
        :ignore_return
      end

      invariant :exclusive do |ob, errors|
        ob.exclusive_invariant_ran
        errors << :extension if ob.set_error
        :ignore_return
      end
    end

    Accord::Interface(TestModule, :OtherExtension) do
      extends TestModule::Base

      responds_to :method1 do
        param :argument
      end
    end
  end

  describe "not constant" do
    it "has a simpler name" do
      expect(not_constant.name).to eq 'NotConstant'
    end
  end

  describe "Base" do
    it "has a name" do
      expect(TestModule::Base.name).to eq 'TestModule::Base'
    end

    it "has :method1" do
      expect(TestModule::Base).to be_defined(:method1)
      expect(TestModule::Base).to be_owns(:method1)
    end

    specify "base's method can be obtained by calling #[]" do
      expect(TestModule::Base[:method1].interface).to be TestModule::Base
    end

    it " has no method :method2" do
      expect(TestModule::Base).to_not be_defined(:method2)
      expect(TestModule::Base).to_not be_owns(:method2)
    end

    it "has a single method" do
      expect(TestModule::Base.method_names).to eq [:method1]
      expect(TestModule::Base.own_method_names).to eq [:method1]
    end

    it "iterates only over :method1" do
      names = []
      methods = []

      TestModule::Base.each do |name, method|
        names << name
        methods << method
      end

      expect(names).to eq [:method1]
      expect(methods.map(&:interface)).to eq [TestModule::Base]
    end

    specify ":method1 doesn't require a parameter" do
      expect(TestModule::Base[:method1].signature_info.arguments).to be_empty
    end

    it "has a tagged value" do
      expect(TestModule::Base.tags[:tag]).to eq :base
    end

    it "can have tags on methods" do
      expect(TestModule::Base[:method1].tags[:tag]).to eq :value
    end

    describe "invariants" do
      let(:ob) { stub(base_invariant_ran: nil, set_error: false) }

      it "runs only one invariant" do
        ob.should_receive(:base_invariant_ran)
        TestModule::Base.assert_invariants?(ob)
      end

      it "returns true if no error is set" do
        result = TestModule::Base.assert_invariants?(ob)
        expect(result).to be_true
      end

      it "returns false if an error is set" do
        ob.stub(set_error: true)
        result = TestModule::Base.assert_invariants?(ob)
        expect(result).to be_false
      end

      it "collects errors" do
        ob.stub(set_error: true)
        errors = []
        TestModule::Base.assert_invariants?(ob, errors)
        expect(errors).to eq [:base]
      end

      describe "with exception" do
        it "raise error if invariant set error" do
          ob.stub(set_error: true)
          expect {
            TestModule::Base.assert_invariants(ob)
          }.to raise_error(Accord::Invalid)
        end

        it "collects errors before raising" do
          ob.stub(set_error: true)
          errors = []
          TestModule::Base.assert_invariants(ob, errors) rescue nil

          expect(errors).to eq [:base]
        end
      end
    end
  end

  describe "Extension" do
    it "has :method1" do
      expect(TestModule::Extension.method_names).to include(:method1)
      expect(TestModule::Extension).to be_defined(:method1)
    end

    it "doesn't owns :method1" do
      expect(TestModule::Extension).to_not be_owns(:method1)
    end

    it "has :method2" do
      expect(TestModule::Extension.method_names).to include(:method1)
      expect(TestModule::Extension).to be_defined(:method2)
    end

    it "owns :method2" do
      expect(TestModule::Extension).to be_owns(:method2)
    end

    it "has :method1 and :method2 defined in this order" do
      expect(TestModule::Extension.method_names).to eq [:method1, :method2]
    end

    it "has :method2 defined in itself" do
      expect(TestModule::Extension.own_method_names).to eq [:method2]
    end

    specify ":method2 requires a parameter with a default value" do
      expect(TestModule::Extension[:method2].signature_info.arguments).to(
        eq([{ name: :param, default: :default }])
      )
    end

    specify "tags are not inherited" do
      expect(TestModule::Extension.tags[:tag]).to be_nil
    end

    specify "tags on methods are inherited if the method is inherited" do
      expect(TestModule::Extension[:method1].tags[:tag]).to eq :value
    end

    describe "invariants" do
      let(:ob) do
        stub(
          set_error: false,
          base_invariant_ran: nil,
          extension_invariant_ran: nil,
          exclusive_invariant_ran: nil,
        )
      end

      it "runs invariants from base" do
        ob.should_receive(:base_invariant_ran)
        TestModule::Extension.assert_invariants?(ob)
      end

      it "runs invariants with the same name as the ones from base" do
        ob.should_receive(:extension_invariant_ran)
        TestModule::Extension.assert_invariants?(ob)
      end

      it "runs invariants included only in extension" do
        ob.should_receive(:exclusive_invariant_ran)
        TestModule::Extension.assert_invariants?(ob)
      end
    end
  end

  describe "OtherExtension" do
    it "overrides :method1 to require an argument" do
      expect(TestModule::OtherExtension[:method1].signature_info.arguments).to(
        eq([{ name: :argument }])
      )
    end

    it "keeps the original method as it was" do
      expect(TestModule::Base[:method1].signature_info.arguments).to be_empty
    end

    specify "tags on methods are not inherited if the method is overridden" do
      expect(TestModule::OtherExtension[:method1].tags[:tag]).to be_nil
    end
  end
end
