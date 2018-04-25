require 'spec_helper'

class Nested < ContentfulModel::Base
  self.content_type_id = 'nested'

  has_many_nested :related
end

class RootNested < ContentfulModel::Base
  self.content_type_id = 'rootNested'

  has_many_nested :related, root: -> { RootNested.find('4UnXECdw6AAwyeCUcIuqCy') }
end

describe ContentfulModel::Associations::HasManyNested do
  before :each do
    ContentfulModel.configure do |c|
      c.space = 'a22o2qgm356c'
      c.access_token = '60229df5876f14f499870d0d26f37b1323764ed637289353a5f74a5ea190c214'
      c.entry_mapping = {}
    end

    Nested.add_entry_mapping
    RootNested.add_entry_mapping
  end

  context 'without root' do
    context 'only has children' do
      it 'parent is nil' do
        vcr('association/nested_without_root_parentless') {
          nested = Nested.find('5CNbxcca5OwgI68eSuWso2')
          expect(nested.parent).to be_nil
        }
      end

      it 'has children' do
        vcr('association/nested_without_root_parentless') {
          nested = Nested.find('5CNbxcca5OwgI68eSuWso2')

          expect(nested.children?).to be_truthy
          expect(nested.children).to be_a ::Array
          expect(nested.children.size).to eq 1
          expect(nested.children.first).to be_a Nested
          expect(nested.children.first.name).to eq 'Nested 2'
        }
      end

      it 'is the root' do
        vcr('association/nested_without_root_parentless') {
          nested = Nested.find('5CNbxcca5OwgI68eSuWso2')
          expect(nested.root?).to be_truthy
          expect(nested.root).to eq nested
        }
      end

      it 'has no ancestors' do
        vcr('association/nested_without_root_parentless') {
          nested = Nested.find('5CNbxcca5OwgI68eSuWso2')
          expect(nested.ancestors).to be_empty
        }
      end

      it 'find ancestors will return self - if passed a block and no ancestors are found' do
        vcr('association/nested_without_root_parentless') {
          nested = Nested.find('5CNbxcca5OwgI68eSuWso2')
          expect(nested.find_ancestors { |a| a }).to eq nested
        }
      end

      it 'find ancestors will be an empty array - if no ancestors and found and no block given' do
        vcr('association/nested_without_root_parentless') {
          nested = Nested.find('5CNbxcca5OwgI68eSuWso2')
          expect(nested.find_ancestors.to_a).to eq []
        }
      end

      it 'creates a tree of children relationships' do
        vcr('association/nested_without_root_parentless_higher_include') {
          nested = Nested.query.params('sys.id' => '5CNbxcca5OwgI68eSuWso2', include: 3).load.first
          child_1 = nested.children.first
          child_2 = child_1.children.first
          expect(nested.nested_children).not_to be_empty
          expect(nested.nested_children).to eq(
            child_1 => {
              child_2 => nil
            }
          )
        }
      end

      it 'creates a tree of children by field' do
        vcr('association/nested_without_root_parentless_higher_include') {
          nested = Nested.query.params('sys.id' => '5CNbxcca5OwgI68eSuWso2', include: 3).load.first
          child_1 = nested.children.first
          child_2 = child_1.children.first
          expect(nested.nested_children_by(:name)).not_to be_empty
          expect(nested.nested_children_by(:name)).to eq(
            child_1.name => {
              child_2.name => nil
            }
          )
        }
      end

      it 'generates flattened structures to use as paths for entries' do
        vcr('association/nested_without_root_parentless_higher_include') {
          nested = Nested.query.params('sys.id' => '5CNbxcca5OwgI68eSuWso2', include: 3).load.first
          child_1 = nested.children.first
          child_2 = child_1.children.first
          expect(nested.all_child_paths_by(:name)).not_to be_empty
          expect(nested.all_child_paths_by(:id)).to eq [[child_1.id, child_2.id]]
        }
      end

      it 'generates a path for entries that match a value' do
        vcr('association/nested_without_root_parentless_higher_include') {
          nested = Nested.query.params('sys.id' => '5CNbxcca5OwgI68eSuWso2', include: 3).load.first
          child_1 = nested.children.first
          child_2 = child_1.children.first
          expect(nested.find_child_path_by(:name, child_2.name)).not_to be_empty
          expect(nested.find_child_path_by(:name, child_2.name)).to eq [[child_1.name, child_2.name]]

          expect(nested.find_child_path_by(:name, 'foo')).to be_empty
        }
      end
    end

    context 'has parent and child' do
      it 'parent exists' do
        vcr('association/nested_without_root_middle') {
          nested = Nested.find('3gpECMvSLSOC8wgkQ6GQ2q')
          expect(nested.parent).to be_a Nested
          expect(nested.parent.name).to eq 'Nested 1'
        }
      end

      it 'has children' do
        vcr('association/nested_without_root_middle') {
          nested = Nested.find('3gpECMvSLSOC8wgkQ6GQ2q')

          expect(nested.children?).to be_truthy
          expect(nested.children).to be_a ::Array
          expect(nested.children.size).to eq 1
          expect(nested.children.first).to be_a Nested
          expect(nested.children.first.name).to eq 'Nested 3'
        }
      end

      it 'is not the root' do
        vcr('association/nested_without_root_middle_parent') {
          nested = Nested.find('3gpECMvSLSOC8wgkQ6GQ2q')
          expect(nested.root?).to be_falsey
          expect(nested.root).to eq nested.parent
        }
      end

      it 'has ancestors' do
        vcr('association/nested_without_root_middle_parent') {
          nested = Nested.find('3gpECMvSLSOC8wgkQ6GQ2q')
          expect(nested.ancestors).not_to be_empty
          expect(nested.ancestors.size).to eq 1
          expect(nested.ancestors.first.name).to eq 'Nested 1'
        }
      end

      it 'find ancestors will return an enumerator of ancestors - if no block given' do
        vcr('association/nested_without_root_middle_parent') {
          nested = Nested.find('3gpECMvSLSOC8wgkQ6GQ2q')
          expect(nested.find_ancestors.to_a.map(&:name)).to eq ['Nested 1']
        }
      end

      it 'find ancestors executes the block for each ancestor - if block given' do
        vcr('association/nested_without_root_middle_parent') {
          nested = Nested.find('3gpECMvSLSOC8wgkQ6GQ2q')

          ancestor_names = []
          nested.find_ancestors { |a| ancestor_names << a.name }

          expect(ancestor_names).to eq ['Nested 1']
        }
      end

      it 'creates a tree of children relationships' do
        vcr('association/nested_without_root_middle_higher_include') {
          nested = Nested.query.params('sys.id' => '3gpECMvSLSOC8wgkQ6GQ2q', include: 3).load.first
          child_1 = nested.children.first
          expect(nested.nested_children).not_to be_empty
          expect(nested.nested_children).to eq(
            child_1 => nil
          )
        }
      end

      it 'creates a tree of children by field' do
        vcr('association/nested_without_root_middle_higher_include') {
          nested = Nested.query.params('sys.id' => '3gpECMvSLSOC8wgkQ6GQ2q', include: 3).load.first
          child_1 = nested.children.first
          expect(nested.nested_children_by(:name)).not_to be_empty
          expect(nested.nested_children_by(:name)).to eq(
            child_1.name => nil
          )
        }
      end

      it 'generates flattened structures to use as paths for entries' do
        vcr('association/nested_without_root_middle_higher_include') {
          nested = Nested.query.params('sys.id' => '3gpECMvSLSOC8wgkQ6GQ2q', include: 3).load.first
          child_1 = nested.children.first
          expect(nested.all_child_paths_by(:name)).not_to be_empty
          expect(nested.all_child_paths_by(:id)).to eq [[child_1.id]]
        }
      end

      it 'generates a path for entries that match a value' do
        vcr('association/nested_without_root_middle_higher_include') {
          nested = Nested.query.params('sys.id' => '3gpECMvSLSOC8wgkQ6GQ2q', include: 3).load.first
          child_1 = nested.children.first
          expect(nested.find_child_path_by(:name, child_1.name)).not_to be_empty
          expect(nested.find_child_path_by(:name, child_1.name)).to eq [[child_1.name]]

          expect(nested.find_child_path_by(:name, 'foo')).to be_empty
        }
      end
    end

    context 'only has parent' do
      it 'parent exists' do
        vcr('association/nested_without_root_childless') {
          nested = Nested.find('2pFubMJuVqMSisGeCmoqem')
          expect(nested.parent).to be_a Nested
          expect(nested.parent.name).to eq 'Nested 2'
        }
      end

      it 'has no children' do
        vcr('association/nested_without_root_childless') {
          nested = Nested.find('2pFubMJuVqMSisGeCmoqem')

          expect(nested.children?).to be_falsey
          expect(nested.children).to be_a ::Array
          expect(nested.children.size).to eq 0
        }
      end

      it 'is not the root' do
        vcr('association/nested_without_root_childless') {
          nested = Nested.find('2pFubMJuVqMSisGeCmoqem')
          expect(nested.root?).to be_falsey
          expect(nested.root.name).to eq 'Nested 1'
        }
      end

      it 'has ancestors' do
        vcr('association/nested_without_root_childless') {
          nested = Nested.find('2pFubMJuVqMSisGeCmoqem')
          expect(nested.ancestors).not_to be_empty
          expect(nested.ancestors.size).to eq 2
        }
      end

      it 'find ancestors will return an enumerator of ancestors - if no block given' do
        vcr('association/nested_without_root_child_parent') {
          nested = Nested.find('2pFubMJuVqMSisGeCmoqem')
          expect(nested.find_ancestors.to_a.map(&:name)).to eq ['Nested 2', 'Nested 1']
        }
      end

      it 'find ancestors executes the block for each ancestor - if block given' do
        vcr('association/nested_without_root_child_parent') {
          nested = Nested.find('2pFubMJuVqMSisGeCmoqem')

          ancestor_names = []
          nested.find_ancestors { |a| ancestor_names << a.name }

          expect(ancestor_names).to eq ['Nested 2', 'Nested 1']
        }
      end

      it 'creates a tree of children relationships' do
        vcr('association/nested_without_root_child_higher_include') {
          nested = Nested.query.params('sys.id' => '2pFubMJuVqMSisGeCmoqem', include: 3).load.first
          expect(nested.nested_children).to be_empty
        }
      end

      it 'creates a tree of children by field' do
        vcr('association/nested_without_root_child_higher_include') {
          nested = Nested.query.params('sys.id' => '2pFubMJuVqMSisGeCmoqem', include: 3).load.first
          expect(nested.nested_children_by(:name)).to be_empty
        }
      end

      it 'generates flattened structures to use as paths for entries' do
        vcr('association/nested_without_root_child_higher_include') {
          nested = Nested.query.params('sys.id' => '2pFubMJuVqMSisGeCmoqem', include: 3).load.first
          expect(nested.all_child_paths_by(:name)).to be_empty
        }
      end

      it 'generates a path for entries that match a value' do
        vcr('association/nested_without_root_child_higher_include') {
          nested = Nested.query.params('sys.id' => '2pFubMJuVqMSisGeCmoqem', include: 3).load.first
          expect(nested.find_child_path_by(:name, 'foo')).to be_empty
        }
      end
    end
  end

  context 'with root' do
    it 'has root method defined' do
      vcr('association/nested_with_root_root') {
        non_root_id = '5sdA4Fv5o4SOeyq4Sq8qmG'
        root_nested = RootNested.find(non_root_id)

        expect(root_nested.name).to eq 'RootNested - 1'
        expect(root_nested.root_root_nested.name).to eq 'RootNested - Root'
      }
    end
  end
end
