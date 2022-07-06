class ProfitCenterVariantsController < DefaultModelController
  include ProfitCenterVariantsHelper

  before_action :set_profit_center_variant, only: [:show, :edit, :update, :destroy]

  # GET /profit_center_variants
  # GET /profit_center_variants.json
  def index
    @profit_center_variants = ProfitCenterVariant.limit(20).all
  end

  # GET /profit_center_variants/1
  # GET /profit_center_variants/1.json
  def show
  end

  # GET /profit_center_variants/new
  def new
    @profit_center_variant = ProfitCenterVariant.new
  end

  # GET /profit_center_variants/1/edit
  def edit
  end

  # POST /profit_center_variants
  # POST /profit_center_variants.json
  def create
    @profit_center_variant = ProfitCenterVariant.new(profit_center_variant_params)

    respond_to do |format|
      if @profit_center_variant.save
        format.html { redirect_to @profit_center_variant, notice: 'Profit center variant was successfully created.' }
        format.json { render :show, status: :created, location: @profit_center_variant }
      else
        format.html { render :new }
        format.json { render json: @profit_center_variant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /profit_center_variants/1
  # PATCH/PUT /profit_center_variants/1.json
  def update
    respond_to do |format|
      if @profit_center_variant.update(profit_center_variant_params)
        format.html { redirect_to @profit_center_variant, notice: 'Profit center variant was successfully updated.' }
        format.json { render :show, status: :ok, location: @profit_center_variant }
      else
        format.html { render :edit }
        format.json { render json: @profit_center_variant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profit_center_variants/1
  # DELETE /profit_center_variants/1.json
  def destroy
    @profit_center_variant.destroy
    respond_to do |format|
      format.html { redirect_to profit_center_variants_url, notice: 'Profit center variant was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # search endpoint for ajax requests
  # POST /profit_center_variants/search
  def search
    # Request should be a POST request, because of the complex params object
    # The params should be part of the payload object
    #
    # Example_object:
    #
    # { :id=>2767, :sap_id=>"16563", :sap_name=>"Imupret N Trpf. 50 ml DE", :status=>"active",
    #   :product_variant=>{:id=>343, :package_size=>50, :weight=>31, :name=>"Dra", :concentration=>0, :dosage_type=>"Dragees", :is_liquid=>false},
    #   :product=>{:id=>86, :name=>"default", :short_name=>nil},
    #   :brand=>{:id=>30, :name=>"Imupret", :short_name=>"IMU"},
    #   :manufacturer=>{:id=>3, :name=>"Bionorica", :short_name=>"BNO", :is_internal=>true},
    #   :country=>{:id=>1224, :name=>"Germany", :iso_code=>"DE", :iso_code3=>"DEU", :business_model=>"Subsidiary", :is_active=>true, :reference_countries=>[], :region=>
    #     {:id=>356, :name=>"Western Europe", :parent_region=>"Europe", :continent=>"Europe", :priority=>0},
    #     :trade_unions=>[{:id=>7, :name=>"European Union", :short_name=>nil, :priority=>0}],
    #     :currency=>{:id=>13, :name=>"Euro", :short_name=>"EUR", :num=>978, :is_main=>true, :exch_rate=>1.0}
    #   }
    # }
    #
    # search can be applied to:
    # ProfitCenterVariants: sap_id, sap_name (full text search), status
    # ProductVariants: package_size, dosage_type, is_liquid (bool)
    # Product: name
    # Brand: name, category_name
    # Country: name, business_model, reference_country (existence - bool)
    # CountryRegion: name, parent region, continent
    # TradeUnions: name
    # Currency: name, short_name
    #
    # Request look like:
    # ProfitCenterVariant.search_by_params(params, page, items_per_page) -> (params, nil, nil)
    #
    # Params should look like:
    # {
    #   profit_center_variants: { sap_ids: [12345, 23456, 66723], sap_names: ['Sinupret Forte Dra 50', 'Bronchipret Drag 50'], status: ['active', 'planned', 'inactive'], show_deductions: false },
    #   product_variants: { package_sizes: [25, 50, 100], dosage_type: ['Dragees', 'Tabs', 'Drops', 'Other'], is_liquid: [true, false] },
    #   products: { names: ['Forte', 'Default', 'eXtrakt']},
    #   brands: { names: ['Sinupret', 'Bronchipret', 'Canephron'], category_names: ['RESP']},
    #   countries: { names: ['Germany', 'Belarus', 'France', 'Spain'], business_models: ['Partner Business', 'Subsidary'], reference_countries: true},
    #   country_regions: { names: ['Western Europe', 'Eastern Europe'], parent_regions: ['Europe', 'Northern America'], continents: ['Europe', 'Asia'] },
    #   trade_unions: { names: ["European Union", "Organization of the Black Sea Economic Cooperation"]},
    #   currencies: { names: ['Euro', 'Rubble', 'Yen'], short_names: ['EUR', 'BYN', 'RUB']},
    #   items_per_page: 20,
    #   page: 1,,
    #   order_by: 'sap_name DESC',
    #   info: false //additional country info & manufacturer info
    # }
    #
    # !!!!!!!! Important info:
    # The request can be complettly empty & will return all objects, any or all of the search params can be empty & won't be applied in that case.
    # Each search term can either be a single item or an array of the same items. Example: sap_names: ['Sinupret Forte Dra 50', 'Bronchipret Drag 50'] or sap_names: 'Sinupret Forte Dra 50'
    #
    # Here is what an example: Ajax Request could look like
    #
    # fetch('/profit_center_variants/search', {
    #     method : "POST",
    #     headers: {
    #       'Content-Type': 'application/json',
    #       'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    #     },
    #     body: JSON.stringify({
    #         profit_center_variants: {sap_ids: [16563, 16564,16573]},
    #         product_variants: {package_size: [50,100], dosage_types: 'Dragees', is_liquid: false },
    #         products: {names: 'default'},
    #         brands: {names: 'Imupret', category_names: 'RESP'},
    #         countries: {names: ['Germany', 'Austria'], business_models: ['Subsidiary', 'Partner Business'], reference_countries: false},
    #         country_regions: {names: ['Western Europe', 'Eastern Asia'], parent_regions: 'Europe', contents: ['Europe', 'Asia']},
    #         trade_unions: {names: ['European Union']},
    #         currencies: {names: ['Euro'], short_names: ['EUR']},
    #         order_by: 'sap_name ASC',
    #         info: true
    #     })
    # }).then(
    #     response => response.text()
    # ).then(
    #     the_json => console.log(the_json)
    # );
    #
    # Return is a json object: {results: 3, items: [------array with objects as described above in the example object ----]}

    the_params = params.transform_keys(&:to_sym)
    the_response = ProfitCenterVariant.pcv_search(the_params)

    respond_to do |format|
      format.json { render json: the_response.to_json }
    end
  end

  # Endpoint for getting all selector items
  # GET /profit_center_variants/selector_data
  def selector_data
      # This endpoints delivers a list of objects with required selector fields
      #
      # objects include:
      # ProfitCenterVariants: status
      # ProductVariants: package_size, dosage_type, is_liquid (bool)
      # Product: name
      # Brand: name
      # Country: name, business_model, reference_country (existence - bool)
      # CountryRegion: name, parent region, continent
      # TradeUnions: name
      # Currency: name, short_name

      # fetch('/profit_center_variants/selector_data', {
      #     method : "GET",
      #     headers: {
      #       'Content-Type': 'application/json',
      #       'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      #     }
      # }).then(
      #     response => response.text()
      # ).then(
      #     the_json => console.log(the_json)
      # );

      the_response = get_pvc_selector_data

      respond_to do |format|
        format.json { render json: the_response.to_json }
      end
  end

  # endpoint for graph data requests
  # GET /profit_center_variants/:profit_center_variant_id/graph_data
  def graph_data
    # Following params are present:
    #
    # object: The type of graph data you exept, available objects are: sales, prices, currencies, details
    # month: int of the month from 1-12
    # year: int of the year from 1995-current_year + 5
    # quarter: int of the quarter 1-4
    # from: Date in format yyyy-mm-dd (any other format won't be accepted)
    # to: Date in format yyyy-mm-dd (any other format won't be accepted)
    # details_key: used to details object request - to provide the required details_key
    #
    # Important Date info!!!!!!
    # if you set a from date and/or to date the time other date params will be overwritten
    # if you set a quarter, the month params will be overwritten
    #
    # Return object will look like this:
    #
    # {
    #   "from_date":"2019-10-01",
    #   "to_date":"2020-03-20",
    #   "object":"sales",
    #   "results": { .... object containing the results - see below ... }
    # }
    #
    # Expected return for objects:
    # --------> sales:
    #
    # { "2020-1"=>{:sales=>576200.26, :items=>97737}, "2020-2"=>{:sales=>682271.15, :items=>117317}, "2020-3"=>{:sales=>351782.05, :items=>58973},
    #   "2020-4"=>{:sales=>150084.64, :items=>25439}, "2020-5"=>{:sales=>108775.23, :items=>18723}, "2020-6"=>{:sales=>195152.97, :items=>33096},
    #   "2020-7"=>{:sales=>90985.6, :items=>15571}, "2020-8"=>{:sales=>103340.45, :items=>17335}, "2020-9"=>{:sales=>317606.75, :items=>52992},
    #   "2020-10"=>{:sales=>385503.8, :items=>64401}, "2020-11"=>{:sales=>326085.96, :items=>54640}, "2020-12"=>{:sales=>260668.24, :items=>43638}
    # }
    #
    # --------> prices:
    #
    # { "2019-10"=>{:cogs=>0.504, :cogs_margin=>1059.725, :list_price=>5.845}, "2019-11"=>{:cogs=>0.504, :cogs_margin=>1059.725, :list_price=>5.845},
    #   "2019-12"=>{:cogs=>0.504, :cogs_margin=>1059.725, :list_price=>5.845}, "2020-1"=>{:cogs=>0.504, :cogs_margin=>1059.725, :list_price=>5.845},
    #   "2020-2"=>{:cogs=>0.504, :cogs_margin=>910.915, :list_price=>5.095}, "2020-3"=>{:cogs=>0.504, :cogs_margin=>910.915, :list_price=>5.095},
    #   "2020-4"=>{:cogs=>0.504, :cogs_margin=>1084.525, :list_price=>5.97}, "2020-5"=>{:cogs=>0.504, :cogs_margin=>1084.525, :list_price=>5.97},
    #   "2020-6"=>{:cogs=>0.504, :cogs_margin=>1084.525, :list_price=>5.97}, "2020-7"=>{:cogs=>0.504, :cogs_margin=>1084.525, :list_price=>5.97}
    # }
    #
    # --------> currencies
    #
    # {
    #   "2020-1":{"exchange_rate":0.0},"2020-2":{"exchange_rate":0.0},"2020-3":{"exchange_rate":0.0},"2020-4":{"exchange_rate":0.0},
    #   "2020-5":{"exchange_rate":0.0},"2020-6":{"exchange_rate":0.0},"2020-7":{"exchange_rate":0.0},"2020-8":{"exchange_rate":0.0},
    #   "2020-9":{"exchange_rate":1.0},"2020-10":{"exchange_rate":0.0},"2020-11":{"exchange_rate":0.0},"2020-12":{"exchange_rate":0.0}
    # }
    # --------> details (for_example_cogs) with corresponding stat_value:
    #
    # { "2019-10"=>{:cogs=>0.504, :cogs_stat=>0.553},
    #   "2019-12"=>{:cogs=>0.504, :cogs_stat=>0.553},
    #   "2020-2"=>{:cogs=>0.504, :cogs_stat=>0.553},
    #   "2020-4"=>{:cogs=>0.504, :cogs_stat=>0.553},
    #   "2020-6"=>{:cogs=>0.504, :cogs_stat=>0.553}
    # }
    #
    # here is an example request (details):
    #
    # fetch('/profit_center_variants/16/graph_data?object=details&from_date=2019-10-01&to_date=2020-05-01&details_key=lp1', {
    #     method : "GET",
    #     headers: {
    #       'Content-Type': 'application/json',
    #       'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    #     }
    # }).then(
    #     response => response.text()
    # ).then(
    #     the_json => console.log(the_json)
    # );

    @profit_center_variant = ProfitCenterVariant.find(params[:profit_center_variant_id])
    the_params = params.transform_keys(&:to_sym)
    object = the_params[:object] ? the_params[:object] : 'error'

    the_response = graph_results_generator(the_params, object)

    respond_to do |format|
      format.json { render json: the_response.to_json }
    end
  end

  # endpoint for graph data requests on search (not individual profit center variants but a collection of them...)
  # POST /profit_center_variants/graph_data
  def search_graph_data
    # Following params are present:
    #
    # object: The type of graph data you exept, available objects are: sales, prices (only sales supported at the moment)
    # month: int of the month from 1-12
    # year: int of the year from 1995-current_year + 5
    # quarter: int of the quarter 1-4
    # from: Date in format yyyy-mm-dd (any other format won't be accepted)
    # to: Date in format yyyy-mm-dd (any other format won't be accepted)
    # !!!!!!!!!-> ids: An array of GPMS IDs of ProfitCenterVariants - example [148,149,150,151,152,153,185,186,187]
    #
    # Important Date info!!!!!!
    # if you set a from date and/or to date the time other date params will be overwritten
    # if you set a quarter, the month params will be overwritten
    #
    # Return object will look like this:
    #
    # {
    #   "from_date":"2019-10-01",
    #   "to_date":"2020-03-20",
    #   "object":"sales",
    #   "results": { .... object containing the results - see below ... }
    # }
    #
    # Expected return for objects:
    # --------> sales:
    #
    # { "2020-1"=>{:sales=>576200.26, :items=>97737}, "2020-2"=>{:sales=>682271.15, :items=>117317}, "2020-3"=>{:sales=>351782.05, :items=>58973},
    #   "2020-4"=>{:sales=>150084.64, :items=>25439}, "2020-5"=>{:sales=>108775.23, :items=>18723}, "2020-6"=>{:sales=>195152.97, :items=>33096},
    #   "2020-7"=>{:sales=>90985.6, :items=>15571}, "2020-8"=>{:sales=>103340.45, :items=>17335}, "2020-9"=>{:sales=>317606.75, :items=>52992},
    #   "2020-10"=>{:sales=>385503.8, :items=>64401}, "2020-11"=>{:sales=>326085.96, :items=>54640}, "2020-12"=>{:sales=>260668.24, :items=>43638}
    # }
    #
    # --------> prices (not implemented yet.....):
    #
    # { "2019-10"=>{:cogs=>0.504, :cogs_margin=>1059.725, :list_price=>5.845}, "2019-11"=>{:cogs=>0.504, :cogs_margin=>1059.725, :list_price=>5.845},
    #   "2019-12"=>{:cogs=>0.504, :cogs_margin=>1059.725, :list_price=>5.845}, "2020-1"=>{:cogs=>0.504, :cogs_margin=>1059.725, :list_price=>5.845},
    #   "2020-2"=>{:cogs=>0.504, :cogs_margin=>910.915, :list_price=>5.095}, "2020-3"=>{:cogs=>0.504, :cogs_margin=>910.915, :list_price=>5.095},
    #   "2020-4"=>{:cogs=>0.504, :cogs_margin=>1084.525, :list_price=>5.97}, "2020-5"=>{:cogs=>0.504, :cogs_margin=>1084.525, :list_price=>5.97},
    #   "2020-6"=>{:cogs=>0.504, :cogs_margin=>1084.525, :list_price=>5.97}, "2020-7"=>{:cogs=>0.504, :cogs_margin=>1084.525, :list_price=>5.97}
    # }
    #
    # here is an example request:
    #
    # fetch('/profit_center_variants/graph_data', {
    #     method : "POST",
    #     headers: {
    #       'Content-Type': 'application/json',
    #       'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    #     },
    #     body: JSON.stringify({
    #       object: 'sales',
    #       from_date: '2020-05-01',
    #       ids: [148,149,150,151,152,153,185,186,187]
    #     })
    # }).then(
    #     response => response.text()
    # ).then(
    #     the_json => console.log(the_json)
    # );

    the_params = params.transform_keys(&:to_sym)
    the_ids = the_params[:ids] ? the_params[:ids] : []
    selector = the_params[:object] ? the_params[:object] : 'error'

    cache_key = [
      "search_graph_data",
      the_params.to_s.gsub(/[\{\"\}\s*]/,'').gsub(',','_').gsub('=>','-').gsub('nil','.').strip
    ].join('___')

    the_response = Rails.cache.fetch(cache_key, :expires_in => 24.hours) do
      the_objects =
        if selector == 'analysisLineChart'
          ProfitCenterVariant.where(gpms_name: the_ids)
        else
          ProfitCenterVariant.where(id: the_ids)
        end
      search_graph_results_generator(the_params, selector, the_objects)
    end

    respond_to do |format|
      format.json { render json: the_response.to_json }
    end
  end

  # POST /profit_center_variants/get_info_card_content
  # params -> type -> available: 'sales', 'items', 'margin', 'counter'
  # example url: /profit_center_variants/get_info_card_content
  # example request
  # fetch('/profit_center_variants/get_info_card_content', {
  #     method : "POST",
  #     headers: {
  #       'Content-Type': 'application/json',
  #       'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
  #     },
  #     body: JSON.stringify({
  #       type: 'sales',
  #       ids: [298, 908, 300, 306, 28, 922, 35, 746, 505, 753, 16, 17, 18, 19, 25, 26, 27, 33, 792, 793]
  #     })
  # }).then(
  #     response => response.text()
  # ).then(
  #     the_json => console.log(the_json)
  # );
  def get_info_card_content
    the_params = params.transform_keys(&:to_sym)

    the_type = the_params[:type].present? ? the_params[:type] : 'sales'
    the_ids = the_params[:ids] ? the_params[:ids] : []
    the_objects = ProfitCenterVariant.where(id: the_ids)
    the_response = {}
    this_month_from = (Time.zone.now - 30.day).beginning_of_month
    this_month_to = (Time.zone.now - 30.day).end_of_month
    last_month_from = (Time.zone.now - 60.days).beginning_of_month
    last_month_to = (Time.zone.now - 60.days).end_of_month

    cache_key = [
      "get_info_card_content",
      the_type.to_s,
      the_ids.to_s,
      this_month_from.to_s,
      this_month_to.to_s,
      last_month_from.to_s,
      last_month_to.to_s
    ].join('___')

    the_response = Rails.cache.fetch(cache_key, :expires_in => 24.hours) do
      if the_type == 'sales'

        sales_this_month = the_objects.get_sales.is_sale.for_euro.valid_between_times(this_month_from,this_month_to)
        sales_last_month = the_objects.get_sales.is_sale.for_euro.valid_between_times(last_month_from,last_month_to)
        sum_this_month = sales_this_month.sum_of_amounts
        sum_last_month = sales_last_month.sum_of_amounts
        difference = 1 - (sum_this_month.to_f / sum_last_month.to_f) * 100
        difference = 0.0 if sales_this_month == sales_last_month
        direction = difference == 0 ? 'eq' : (difference >= 0 ? "up" : "down")

        the_response = {
          sales_this_month: sum_this_month.round(2),
          difference: difference.round(2),
          direction: direction
        }
      elsif the_type == 'items'
        sales_this_month = the_objects.get_sales.is_sale.for_euro.valid_between_times(this_month_from,this_month_to)
        sales_last_month = the_objects.get_sales.is_sale.for_euro.valid_between_times(last_month_from,last_month_to)
        sum_this_month = sales_this_month.sum_of_items
        sum_last_month = sales_last_month.sum_of_items
        difference = 1 - (sum_this_month.to_f / sum_last_month.to_f) * 100
        difference = 0.0 if sales_this_month == sales_last_month
        direction = difference == 0 ? 'eq' : (difference >= 0 ? "up" : "down")

        the_response = {
          units_this_month: sum_this_month.round(2),
          difference: difference.round(2),
          direction: direction
        }
      elsif the_type == 'margin'
        margin_hash = the_objects.get_avg_margins

        margin_this_month = margin_hash[:this_month]
        margin_last_month = margin_hash[:last_month]
        difference = 1 - (margin_this_month.to_f / margin_last_month.to_f) * 100
        difference = 0.0 if margin_this_month == margin_last_month
        direction = difference == 0 ? 'eq' : (difference >= 0 ? "up" : "down")

        the_response = {
          margin_this_month: margin_this_month.round(2),
          difference: difference.round(2),
          direction: direction
        }
      elsif the_type == 'counter'
        the_response = the_objects.get_search_data_counters
      end

      the_response
    end

    respond_to do |format|
      format.json { render json: the_response.to_json }
    end
  end

  # POST /profit_center_variants/get_search_buildup_info
  # example url: /profit_center_variants/get_search_buildup_info
  def get_search_buildup_info
    the_params = params.transform_keys(&:to_sym)
    the_type = the_params[:type].present? ? the_params[:type] : 'sales'
    the_ids = the_params[:ids] ? the_params[:ids] : []
    the_date = Time.zone.parse(the_params[:date])
    the_objects = ProfitCenterVariant.where(id: the_ids)

    the_response = {}

    cache_key = [
      "get_search_buildup_info",
      the_type.to_s,
      the_ids.to_s,
      current_user.elevated?,
      the_date.to_date.to_s
    ].join('___')

    the_response = Rails.cache.fetch(cache_key, :expires_in => 24.hours) do
      begin
        the_response = {
          buildup_data: the_objects.get_search_buildups(current_user.elevated?, 'eur', the_date),
          status: 'success'
        }
      rescue => e
        the_response = {
          buildup_data: {},
          status: 'error'
        }
      end
      the_response
    end

    respond_to do |format|
      format.json { render json: the_response.to_json }
    end
  end

  def get_price_buildup_price_info
    the_params = params.transform_keys(&:to_sym)
    pcv = ProfitCenterVariant.find(the_params[:id])
    price_info = pcv.get_price_info_in_currency(params[:currency_type])

    respond_to do |format|
      format.json { render json: price_info.to_json }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_profit_center_variant
      @profit_center_variant = ProfitCenterVariant.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def profit_center_variant_params
      params.require(:profit_center_variant).permit(:profit_center_id, :product_variant_id, :sap_id, :sap_name, :status, :is_visible, :short_name, :gpms_name)
    end
end
