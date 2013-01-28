require 'spec_helper'

describe Analyzing::Mongoid::InlineEmbeds do
  let(:klass) do
    Class.new do
      cattr_accessor :name
      self.name = 'Post'
      include Mongoid::Document
      include Analyzing::Mongoid::InlineEmbeds
    end
  end

  describe '.embeds_one_inline' do
    before do
      klass.embeds_one_inline(:creator) do
        field :name
      end
    end

    let(:creator) do
      klass.const_get :Creator
    end

    it 'creates an embedded document class inside the original class' do
      expect(klass.constants).to include :Creator
      expect(creator.ancestors).to include Mongoid::Document
    end

    it 'includes inline embeds into created embedded class' do
      expect(creator.ancestors).to include Analyzing::Mongoid::InlineEmbeds
    end

    it 'defines created class as being embedded_in into parent class' do
      expect(creator.relations['parent']).to be_present
      expect(creator.relations['parent'].class_name).to eq 'Post'
    end

    it 'evaluates passed block in context of created class' do
      expect(creator.fields['name']).to be_present
    end

    it 'defines embeds_one relationship' do
      expect(klass.relations['creator']).to be_present
      expect(klass.relations['creator'].relation).to eq Mongoid::Relations::Embedded::One
    end
  end

  describe '.embeds_many_inline' do
    before do
      klass.embeds_many_inline(:comments) do
        field :body
      end
    end

    let(:comment) do
      klass.const_get :Comment
    end

    it 'creates an embedded document class inside the original class' do
      expect(klass.constants).to include :Comment
      expect(comment.ancestors).to include Mongoid::Document
    end

    it 'includes inline embeds into created embedded class' do
      expect(comment.ancestors).to include Analyzing::Mongoid::InlineEmbeds
    end

    it 'defines created class as being embedded_in into parent class' do
      expect(comment.relations['parent']).to be_present
      expect(comment.relations['parent'].class_name).to eq 'Post'
    end

    it 'evaluates passed block in context of created class' do
      expect(comment.fields['body']).to be_present
    end

    it 'defines embeds_many relationship' do
      expect(klass.relations['comments']).to be_present
      expect(klass.relations['comments'].relation).to eq Mongoid::Relations::Embedded::Many
    end
  end
end
