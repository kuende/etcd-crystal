module Etcd
  class Config
    macro field(attr, class_type, default_value)
      @{{attr.id}} = {{default_value}}

      def {{attr.id}} : {{class_type}}
        @{{attr.id}}
      end

      def {{attr.id}}=(value : {{class_type}})
        @{{attr.id}} = value
      end
    end

    field :use_ssl, Bool, false
    field :read_timeout, Int, 60
    field :verify_mode, Symbol, :none
    field :user_name, String, ""
    field :password, String, ""
    field :ca_file, String, ""
    field :ssl_cert, String, ""
  end
end
