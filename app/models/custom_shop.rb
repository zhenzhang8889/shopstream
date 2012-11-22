class CustomShop < Shop
  after_create :email_instructions

  def email_instructions
    InstructionsMailer.instructions(self, user).deliver
  end
end
