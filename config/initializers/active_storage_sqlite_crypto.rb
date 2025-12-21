Rails.application.config.to_prepare do
  ActiveStorage::Blob.generates_uuid :id
  ActiveStorage::Attachment.generates_uuid :id
  ActiveStorage::VariantRecord.generates_uuid :id
end