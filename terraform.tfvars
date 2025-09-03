subnets = [{
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  public            = true
  require_nat       = false
  app               = false
  }, {
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"
  public            = false
  require_nat       = true
  app               = true
  },
  {
    cidr_block        = "10.0.20.0/24"
    availability_zone = "us-east-1a"
    public            = false
    require_nat       = true
    app               = false
}]
