import * as React from "react";
exports.createPages = async ({ graphql, actions }) => {
  const { createRedirect } = actions;

  createRedirect({
    fromPath: `^/install.sh$`,
    toPath: `https://get.bacalhau.org/install.sh`,
  });
};
const IndexPage = () => {
  return (
    <head>
      <meta
        http-equiv="refresh"
        content="0; URL='https://get.bacalhau.org/install.sh'"
      />
    </head>
  );
};

export default IndexPage;
