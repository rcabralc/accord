require 'spec_helper'
require 'accord'
require 'accord/interfaces'

describe "Verification" do
  before do
    stub_const('TestModule', Module.new)

    Accord::Interface(TestModule, :B1) do
      responds_to :method1
    end

    Accord::Interface(TestModule, :B2) do
      responds_to :method2, params: :arg
    end

    Accord::Interface(TestModule, :B3) do
      responds_to :method3, params: [ :arg1, :arg2 ]
    end

    Accord::Interface(TestModule, :B4) do
      responds_to :method4, params: [ :arg1, { arg2: :default } ]
    end

    Accord::Interface(TestModule, :B5) do
      responds_to :method5, params: [ :arg1, :"*arg2", :"&block" ]
    end

    Accord::Interface(TestModule, :I) do
      extends TestModule::B1
      extends TestModule::B2
      extends TestModule::B3
      extends TestModule::B4
      extends TestModule::B5
    end
  end

  describe "objects" do
    let(:candidate) { Object.new }

    context "when candidate not even provides the interface" do
      it "raises DoesNotImplement" do
        expect {
          TestModule::I.verify_object(candidate)
        }.to raise_error(Accord::DoesNotImplement)
      end
    end

    context "when candidate at least provides the interface" do
      before do
        Accord::Declarations.also_provides(candidate, TestModule::I)
      end

      context "when candidate has none of the methods" do
        it "raises BrokenImplementation" do
          expect {
            TestModule::I.verify_object(candidate)
          }.to raise_error(Accord::BrokenImplementation)
        end
      end

      context "when candidate is missing one of the methods" do
        it "raises BrokenImplementation" do
          def candidate.method1; end
          def candidate.method2(a1, a2); end
          def candidate.method3(a1, a2=:any); end
          expect {
            TestModule::I.verify_object(candidate)
          }.to raise_error(Accord::BrokenImplementation)
        end
      end

      context "when the candidate has all methods, but signatures don't "\
              "match" do
        it "raises BrokenImplementation" do
          def candidate.method1; end
          def candidate.method2(a1); end
          def candidate.method3(a1, a2); end
          def candidate.method4(a1, a2); end
          def candidate.method5; end
          expect {
            TestModule::I.verify_object(candidate)
          }.to raise_error(Accord::BrokenImplementation)
        end
      end

      context "when all methods match signature" do
        it "doesn't raise" do
          def candidate.method1; end
          def candidate.method2(a1); end
          def candidate.method3(a1, a2); end
          def candidate.method4(a1, a2=:any); end
          def candidate.method5(a1, *a2, &block); end
          expect {
            TestModule::I.verify_object(candidate)
          }.to_not raise_error(Accord::BrokenImplementation)
        end
      end

      context "when a method has a default as last argument" do
        it "doesn't raise if it still can be called with that argument" do
          def candidate.method1(a1=nil); end
          def candidate.method2(a1, a2=nil); end
          def candidate.method3(a1, a2=nil); end
          def candidate.method4(a1, a2=:any); end
          def candidate.method5(a1, *a2, &block); end
          expect {
            TestModule::I.verify_object(candidate)
          }.to_not raise_error(Accord::BrokenImplementation)
        end
      end
    end
  end

  describe "module" do
    let(:candidate) { Module.new }

    context "when candidate not even implements the interface" do
      it "raises DoesNotImplement" do
        expect {
          TestModule::I.verify_module(candidate)
        }.to raise_error(Accord::DoesNotImplement)
      end
    end

    context "when candidate at least implements the interface" do
      before do
        Accord::Declarations.implements(candidate, TestModule::I)
      end

      context "when candidate has none of the methods" do
        it "raises BrokenImplementation" do
          expect {
            TestModule::I.verify_module(candidate)
          }.to raise_error(Accord::BrokenImplementation)
        end
      end

      context "when candidate is missing one of the methods" do
        it "raises BrokenImplementation" do
          candidate.module_eval do
            def method1; end
            def method2(a1, a2); end
            def method3(a1, a2=:any); end
          end
          expect {
            TestModule::I.verify_module(candidate)
          }.to raise_error(Accord::BrokenImplementation)
        end
      end

      context "when the candidate has all methods, but signatures don't "\
              "match" do
        it "raises BrokenImplementation" do
          candidate.module_eval do
            def method1; end
            def method2(a1); end
            def method3(a1, a2); end
            def method4(a1, a2); end
            def method5; end
          end
          expect {
            TestModule::I.verify_module(candidate)
          }.to raise_error(Accord::BrokenImplementation)
        end
      end

      context "when all methods match signature" do
        it "doesn't raise" do
          candidate.module_eval do
            def method1; end
            def method2(a1); end
            def method3(a1, a2); end
            def method4(a1, a2=:any); end
            def method5(a1, *a2, &block); end
          end
          expect {
            TestModule::I.verify_module(candidate)
          }.to_not raise_error(Accord::BrokenImplementation)
        end
      end

      context "when a method has a default as last argument" do
        it "doesn't raise if it still can be called with that argument" do
          candidate.module_eval do
            def method1(a1=nil); end
            def method2(a1, a2=nil); end
            def method3(a1, a2=nil); end
            def method4(a1, a2=:any); end
            def method5(a1, *a2, &block); end
          end
          expect {
            TestModule::I.verify_module(candidate)
          }.to_not raise_error(Accord::BrokenImplementation)
        end
      end
    end
  end

  module Accord
    describe "implementations" do
      specify "interfaces should be implemented" do
        Interfaces::Tags.verify_module(Tags)
        Interfaces::SignatureInfo.verify_module(SignatureInfo)
        Interfaces::Method.verify_module(InterfaceMethod)
        Interfaces::Specification.verify_module(Specification)
        Interfaces::Interface.verify_module(InterfaceClass)
        Interfaces::Declaration.verify_module(Declarations::Declaration)
        Interfaces::InterfaceDeclarations.verify_object(Declarations)
        Interfaces::AdapterRegistry.verify_module(AdapterRegistry)
        Interfaces::SubscriptionRegistry.verify_module(SubscriptionRegistry)
        Interfaces::InterfaceBody.verify_module(InterfaceBody)
      end
    end
  end
end
