module Kiwi
  class Image
    class XmlParser
      def initialize(xml_string, md5)
        @xml_string = xml_string
        @md5 = md5
      end

      def parse
        return blank_image if xml_hash.blank?

        new_image = Kiwi::Image.new(name: xml_hash['name'], md5_last_revision: @md5)

        new_image.use_project_repositories = use_project_repositories?
        new_image.repositories = repositories
        new_image.package_groups = package_groups
        new_image.description = description

        new_image
      end

      private

      def xml_hash
        @xml_hash ||= Xmlhash.parse(@xml_string)
      end

      def blank_image
        Kiwi::Image.new(name: 'New Image: Please provide a name', md5_last_revision: @md5)
      end

      def repositories_from_xml
        @repositories_from_xml ||= [xml_hash["repository"]].flatten.compact
      end

      def use_project_repositories?
        repositories_from_xml.any? do |repository|
          repository['source']['path'] == 'obsrepositories:/'
        end
      end

      # Return an array of Kiwi::Repository models from the parsed xml
      def repositories
        repositories_from_xml.reject{ |repository| repository['source']['path'] == 'obsrepositories:/' }.map.with_index(1) do |repository, index|
          attributes = {
            repo_type:   repository['type'],
            source_path: repository['source']['path'],
            priority:    repository['priority'],
            order:       index,
            alias:       repository['alias'],
            replaceable: repository['status'] == 'replaceable',
            username:    repository['username'],
            password:    repository['password']
          }
          attributes['imageinclude'] = repository['imageinclude'] == 'true' if repository.key?('imageinclude')
          attributes['prefer_license'] = repository['prefer-license'] == 'true' if repository.key?('prefer-license')

          Repository.new(attributes)
        end
      end

      # Return an array of Kiwi::PackageGroup models, including their related Kiwi::Package models, from the parsed xml
      def package_groups
        package_groups = []

        [xml_hash["packages"]].flatten.compact.each do |package_group_xml|
          package_group = Kiwi::PackageGroup.new(
            kiwi_type:    package_group_xml['type'],
            profiles:     package_group_xml['profiles '],
            pattern_type: package_group_xml['patternType']
          )

          [package_group_xml['package']].flatten.compact.each do |package_xml|
            attributes = {
              name:     package_xml['name'],
              arch:     package_xml['arch'],
              replaces: package_xml['replaces']
            }
            attributes['bootinclude'] = package_xml['bootinclude'] == 'true' if package_xml.key?('bootinclude')
            attributes['bootdelete'] = package_xml['bootdelete'] == 'true' if package_xml.key?('bootdelete')

            package_group.packages.build(attributes)
          end

          package_groups << package_group
        end

        package_groups
      end

      # Return an instance of Kiwi::Description model from the parsed xml
      def description
        attributes = [xml_hash["description"]].flatten.find do |description|
          description['type'] == 'system'
        end

        return if attributes.blank?

        Kiwi::Description.new(
          description_type: attributes['type'],
          author:           attributes['author'],
          contact:          attributes['contact'],
          specification:    attributes['specification']
        )
      end
    end
  end
end
