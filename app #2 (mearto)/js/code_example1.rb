desc 'Create fake items for home page'
  task create_fake_items: :environment do
    category = Category.first
    channel = Channel.find_by(name: 'mearto')
    country = "US"

    puts "Finding Seller..."
    seller = Seller.find_by(email: 'test_fake_seller@gmail.com')

    seller ||= Seller.create!(
      first_name: 'Jane',
      last_name: 'Air',
      email: 'test_fake_seller@gmail.com',
      country_id: country,
      password: '--INSERT-PWD-HERE--',
      channel: channel
    )

    puts "Creating Items..."
    [
      'sculpture',
      'bottles',
      'ring',
      'bonnard',
      'french_clock',
      'canvas'
    ].each do |item_name|
      next if Item.find_by(slug: "#{item_name}-slug")

      item = Item.create!(
        category: category,
        seller: seller,
        channel: channel,
        description: 'Example of discription',
        provenance: 'Example of provenance',
        private: false,
        acquired_from: 'Auction House',
        is_for_sale: 1,
        title: "#{item_name} homepage",
        currency: 'USD',
        state: :resolved
      )
      puts "Item #{item_name} created."

      item_image = item.item_images.build
      item_image.image.attach(
        io: File.open("./app/assets/images/home/#{item_name}.png"),
        filename: "#{item_name}.png",
        content_type: 'image/png'
      )
      item_image.save!
      puts "Image #{item_name}.png saved."
    end
  end