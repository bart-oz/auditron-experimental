Bullet.add_safelist :type => :unused_eager_loading, :class_name => "ActiveStorage::Attachment", :association => :record

Bullet.add_safelist :type => :unused_eager_loading, :class_name => "ActiveStorage::Attachment", :association => :blob

Bullet.add_safelist :type => :unused_eager_loading, :class_name => "ActiveStorage::Blob", :association => :variant_records

Bullet.add_safelist :type => :unused_eager_loading, :class_name => "ActiveStorage::Blob", :association => :preview_image_attachment