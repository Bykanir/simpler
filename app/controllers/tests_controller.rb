class TestsController < Simpler::Controller

  def index
    @time = Time.now

    render plain: "Plain text response", status: 201
  end

  def show
    
  end

  def create

  end

end
