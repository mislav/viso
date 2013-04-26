module SocialHelper
  def self.registered(app)
    app.helpers SocialHelper
  end

  def social_meta_data_for(drop)
    return if drop.pending? or not drop.image?

    %{<meta property="og:site_name" content="CloudApp">
      <meta property="og:title" content="#{escape_html drop.name}">
      <meta property="og:image" content="#{drop.remote_url}">
      <meta property="og:url" content="#{drop.share_url}">
      <meta name="twitter:image" value="#{drop.remote_url}">
      <meta name="twitter:card" value="photo">
      <meta name="twitter:site" value="@cloudapp">}
  end
end
