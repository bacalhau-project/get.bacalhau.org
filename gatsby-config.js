module.exports = {
  siteMetadata: {
    title: "Bacalhau",
    description: "Fine service of compute over data.",
    siteUrl: "https://bacalhau.org",
    twitterUsername: "@bacalhauproject",
  },
  plugins: [
    {
      resolve: "gatsby-plugin-react-svg",
      options: {
        rule: {
          include: /svg-assets/,
        },
      },
    },
    "gatsby-plugin-sitemap",
    {
      resolve: "gatsby-plugin-manifest",
      options: {
        name: `Get Bacalhau`,
        short_name: `Get Bacalhau`,
        description: `Get Bacalhau Install Script`,
        lang: `en`,
        display: `standalone`,
        start_url: `/`,
        background_color: `#390048`,
        theme_color: `#AD6CD6`,
        icon: "./src/images/bacalhau-logo.svg",
      },
    },
    "gatsby-plugin-sharp",
    "gatsby-transformer-sharp",
    {
      resolve: "gatsby-source-filesystem",
      options: {
        name: "images",
        path: "./src/images/",
      },
      __key: "images",
    },
    "gatsby-plugin-meta-redirect", // make sure to put last in the array
  ],
};
