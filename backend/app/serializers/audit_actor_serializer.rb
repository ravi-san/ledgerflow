class AuditActorSerializer
  include JSONAPI::Serializer

  set_type :user

  attributes :email
end
