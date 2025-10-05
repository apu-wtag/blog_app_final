module HtmlHelpers
  def unescaped_response_body
    CGI.unescapeHTML(response.body)
  end
  def expect_body_to_include(text)
    expect(unescaped_response_body).to include(text)
  end
  def expect_body_not_to_include(text)
    expect(unescaped_response_body).not_to include(text)
  end
end
