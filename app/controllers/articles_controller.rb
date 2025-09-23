class ArticlesController < ApplicationController
  before_action :require_login, only: %i[ new create edit update destroy ]
  before_action :set_article, only: %i[ show edit update destroy toggle_clap ]
  before_action :authorize_upload, only: %i[ upload_image fetch_image_url upload_file ]

  # GET /articles or /articles.json
  def index
    @query = params[:query]
    @scope = params[:scope] || "articles"

    if @scope == "articles"
      articles = policy_scope(Article).kept
      articles = articles.includes(user: { profile_picture_attachment: :blob })
      if @query.present?
        search_query = "%#{@query}%"
        articles = articles.joins(:user).where(
          "articles.title ILIKE ? OR articles.content::text ILIKE ? OR users.name ILIKE ?",
          search_query, search_query, search_query
        )
      end
      @pagy, @results = pagy(articles.order(created_at: :desc), items: 10)
    elsif @scope == "people"
      users = policy_scope(User) rescue User.kept
      users = users.includes(profile_picture_attachment: :blob)
      if @query.present?
        search_query = "%#{@query}%"
        users = users.where("name ILIKE ? OR user_name ILIKE ?", search_query, search_query)
      end
      @pagy, @results = pagy(users.order(:name), items: 10)
    end
  end


  # GET /articles/1 or /articles/1.json
  def show
    authorize @article
    @comments = @article.comments.kept.where(parent_id: nil)
                        .includes(user: { profile_picture_attachment: :blob },
                                  replies: { user: { profile_picture_attachment: :blob } })
                        .order(created_at: :desc)
  end

  # GET /articles/new
  def new
    @article = Article.new
    authorize @article
  end

  # GET /articles/1/edit
  def edit
    authorize @article
  end

  # POST /articles or /articles.json
  def create
    @article = current_user.articles.build(article_params)
    authorize @article
    respond_to do |format|
      if @article.save
        format.html { redirect_to @article, notice: "Article was successfully created." }
        format.json { render :show, status: :created, location: @article }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1 or /articles/1.json
  def update
    authorize @article
    note = article_params.delete(:author_note)
    respond_to do |format|
      if @article.update(article_params)
        if @article.discarded? && @article.user == current_user
          record = @article.moderation_records.last || @article.moderation_records.build
          record.update(author_note: note, status: :pending_review)
          format.html { redirect_to @article, notice: "Article updated and submitted for review.", status: :see_other }
          format.json { render :show, status: :ok, location: @article }
        else
          format.html { redirect_to @article, notice: "Article was successfully updated.", status: :see_other }
          format.json { render :show, status: :ok, location: @article }
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1 or /articles/1.json
  def destroy
    authorize @article
    @article.destroy!

    respond_to do |format|
      format.html { redirect_to articles_path, notice: "Article was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end
  def upload_image
    # Rails.logger.info "---- DEBUG: RUNNING NEW UPLOAD_IMAGE METHOD ----"
    file = params[:file]
    if file
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename)
      # Rails.logger.info "---- DEBUG: BLOB SIGNED ID IS: #{blob.signed_id} ----"
      render json: {
        success: 1,
        file: {
          url: url_for(blob),
          signed_id: blob.signed_id
        }
      }
    else
      render json: {success: 0, message: "No file provided"}, status: :unprocessable_entity
    end
  end

  def fetch_image_url
    # Rails.logger.info "---- DEBUG: RUNNING Fetch METHOD ----"

    url = params[:url]
    if url
      io = URI.open(url)
      filename = File.basename(URI.parse(url).path)
      blob = ActiveStorage::Blob.create_and_upload!(io: io, filename: filename)
      # Rails.logger.info "---- DEBUG: BLOB SIGNED ID IS: #{blob.signed_id} ----"
      render json: {
        success: 1,
        file: {
          url: url_for(blob),
          signed_id: blob.signed_id 
        }
      }
    else
      render json: { success: 0, message: "No URL provided" }, status: :unprocessable_entity
    end
  rescue => e
    render json: { success: 0, message: e.message }, status: :unprocessable_entity
  end

  def upload_file
    # Rails.logger.info "---- DEBUG: RUNNING UPLOAD FILE METHOD ----"
    file = params[:file]
    if file
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename)
      # Rails.logger.info "---- DEBUG: BLOB SIGNED ID IS: #{blob.signed_id} ----"
      render json: {
        success: 1,
        file: {
          url: url_for(blob),
          signed_id: blob.signed_id,
          size: blob.byte_size,
          name: blob.filename.to_s,
          title: blob.filename.to_s,
          extension: blob.filename.extension
        }
      }
    else
      render json: { success: 0, message: "No file provided" }, status: :unprocessable_entity
    end
  end
  def toggle_clap
    clap = current_user.claps.find_by(article_id: @article.id)
    clap ? clap.destroy : current_user.claps.create!(article_id: @article.id)
    @article.reload

    respond_to do |format|
      format.turbo_stream
    end
  end

  private
    def set_article
      @article = Article.all.friendly.find(params.expect(:id))
      # If an old id or a numeric id was used to find the record, then
      # the request path will not match the post_path, and we should do
      # a 301 redirect that uses the current friendly id.
      if action_name == "show" && request.path != article_path(@article)
        redirect_to @article, status: :moved_permanently
      end
    end
    def authorize_upload
      if params[:article_id].present?
        article = Article.friendly.find(params[:article_id])
        authorize article, :update?
      else
        authorize Article, :create?
      end
    end
    def article_params
      params.expect(article: [ :title, :content, :topic_name, :author_note ])
    end
end
