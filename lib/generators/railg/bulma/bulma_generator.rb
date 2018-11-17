module Railg
  class BulmaGenerator < ::Rails::Generators::Base
    def insert_bulma_link_tag
      insert_into_file 'app/views/layouts/application.html.erb', <<-TAG, before: "  </head>\n"
    <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.2/css/bulma.min.css'>
      TAG
    end

    def insert_fontawesome_script_tag
      insert_into_file 'app/views/layouts/application.html.erb', <<-TAG, before: "  </head>\n"
    <script defer src='https://use.fontawesome.com/releases/v5.3.1/js/all.js'></script>
      TAG
    end
  end
end
