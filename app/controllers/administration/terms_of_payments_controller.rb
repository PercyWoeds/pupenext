class Administration::TermsOfPaymentsController < AdministrationController
  helper_method :showing_not_used?

  # GET /terms_of_payments
  def index

    @terms_of_payments = current_company.terms_of_payments
      .search_like(search_params)
      .order(order_params)

    if showing_not_used?
      @terms_of_payments = @terms_of_payments.not_in_use
    else
      @terms_of_payments = @terms_of_payments.in_use
    end
  end

  # GET /terms_of_payments/1
  def show
    render 'edit'
  end

  # GET /terms_of_payments/new
  def new
    @terms_of_payment = current_company.terms_of_payments.build
  end

  # GET /terms_of_payments/1/edit
  def edit
  end

  # POST /terms_of_payments
  def create
    @terms_of_payment = current_company.terms_of_payments.build(terms_of_payment_params)

    if @terms_of_payment.save_by current_user
      redirect_to terms_of_payments_path, notice: t('Maksuehto luotiin onnistuneesti')
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /terms_of_payments/1
  def update
    if @terms_of_payment.update_by(terms_of_payment_params, current_user)
      redirect_to terms_of_payments_path, notice: t('Maksuehto päivitettiin onnistuneesti')
    else
      render action: 'edit'
    end
  end

  private

    def terms_of_payment_params
      params.require(:terms_of_payment).permit(
        :teksti,
        :rel_pvm,
        :abs_pvm,
        :kassa_relpvm,
        :kassa_abspvm,
        :kassa_alepros,
        :jv,
        :kateinen,
        :factoring,
        :pankkiyhteystiedot,
        :itsetulostus,
        :jaksotettu,
        :erapvmkasin,
        :sallitut_maat,
        :kaytossa,
        :jarjestys
      )
    end

    def find_resource
      @terms_of_payment = current_user.company.terms_of_payments.find(params[:id])
    end

    def showing_not_used?
      params[:not_used] ? true : false
    end

    def searchable_columns
      [
        :teksti,
        :rel_pvm,
        :abs_pvm,
        :kassa_relpvm,
        :kassa_abspvm,
        :kassa_alepros,
        :jarjestys,
      ]
    end

    def sortable_columns
      searchable_columns
    end
end
