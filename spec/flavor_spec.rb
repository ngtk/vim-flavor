require 'spec_helper'

module Vim
  module Flavor
    describe Flavor do
      describe '#versions_from_tags' do
        def example tags, versions
          f = Flavor.new()
          expect(f.versions_from_tags(tags).sort.map(&:version)).to be ==
            versions
        end

        it 'converts tags into versions' do
          example ['1.2', '2.4.6', '3.6'], ['1.2', '2.4.6', '3.6']
        end

        it 'accepts also prelerease tags' do
          example ['1.2a', '2.4.6b', '3.6c'], ['1.2a', '2.4.6b', '3.6c']
        end

        it 'drops non-version tags' do
          example ['1.2', '2.4.6_', 'test', '2.9'], ['1.2', '2.9']
        end
      end

      describe '#satisfied_with?' do
        subject {
          f = Flavor.new()
          f.repo_name = 'foo'
          f.version_constraint = VersionConstraint.new('>= 1.2.3')
          f
        }

        def version(s)
          Version.create(s)
        end

        it {is_expected.to be_satisfied_with version('1.2.3')}

        it {is_expected.to be_satisfied_with version('1.2.4')}
        it {is_expected.to be_satisfied_with version('1.3.3')}
        it {is_expected.to be_satisfied_with version('2.2.3')}

        it {is_expected.not_to be_satisfied_with version('0.2.3')}
        it {is_expected.not_to be_satisfied_with version('1.1.3')}
        it {is_expected.not_to be_satisfied_with version('1.2.2')}
      end

      describe '#mercurial?' do
        subject do
          f = Flavor.new
          f.repo_name = repo_name
          f
        end

        context 'repo_name is ssh://hg@bitbucket.org/hoo/bar' do
          let(:repo_name) { 'ssh://hg@bitbucket.org/hoo/bar' }
          it { is_expected.to be_mercurial }
        end

        context 'repo_name is https://github.com/hoo/bar.git' do
          let(:repo_name) { 'https://github.com/hoo/bar.git' }
          it { is_expected.not_to be_mercurial }
        end
      end
    end
  end
end

