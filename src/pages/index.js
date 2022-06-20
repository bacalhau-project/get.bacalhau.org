import * as React from "react";
exports.createPages = async ({ graphql, actions }) => {
  const { createRedirect } = actions;

  createRedirect({
    fromPath: `^/index.sh$`,
    toPath: `https://get.bacalhau.org/index.sh`,
  });
};
const IndexPage = () => {
  return (
    <head>
      <meta
        http-equiv="refresh"
        content="0; URL='https://get.bacalhau.org/index.sh'"
      />
    </head>
  );
};

export default IndexPage;
