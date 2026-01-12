# How to Contribute

This project is [licensed](./LICENSE) and accepts contributions via GitHub pull
requests. In this document, we outline some of the conventions on development
workflow, commit message formatting, contact points and other resources to make
it easier to get your contribution accepted.

## Getting Started

* Fork the repository.
* Read the [README.md](./README.md) for usage/test instructions.
* Play with the project, submit bugs or patches.

### Contribution Flow

On the contributors' side:
1. Create a topic branch from the main brach to base your work on.
2. Make commits of logical units.
3. Push changes to a topic branch in your GitHub fork of this
repository.
4. Make sure to validate changes by running tests on a
EWC environment.
5. Submit a pull request to this repository, including details on
the steps necessary to reproduce your tests; assign maintainers for
review/approval.

On the maintainers' side:

1. Review, validate/test internally, and provide feedback prior to approving
the pull request.
2. Upon approval, squash-merge the changes, making sure to provide a relevant
conventional commit message title (checkout
[commit guidelines](#commit-guidelines) below).
3. Update the README in the main branch to summarize any breaking changes and the version in the title (follow [this example](https://github.com/actions/checkout/blob/0c366fd6a839edf440554fa01a7085ccba70ac98/README.md?plain=1#L3-L16))
4. Create a new `git tag` following [Semantic Versioning](https://semver.org/) standard on the main branch, and replace the latest tag to point to it. For example, if releasing a fix on top of `1.5.0`:
    ```bash
    git tag 1.5.1 -m "1.5.1" && git push --tags
    ```
    ```bash
    git push -d origin tags/v1 && git tag -d v1 && git tag v1 -m "1.5.1" && git push --tags
    ```


### Commit Guidelines

This repository enforces
[conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
to mark breaking, major and minor code changes in accordance with the
[Semantic Versioning](https://semver.org/) standard:
- Commits that land on the main branch should always be prefixed by a
specific keyword (i.e. `docs`, `style`, `feat`, `fix`, `refactor`, `ci`,
`chore` or `test`)
- Value is communicated to the end-users by three of the prefixes:
  - `fix`: Patches a bug in your codebase.
  - `feat`: Introduces a new feature to the codebase.
  - `BREAKING CHANGE`: Introduces a breaking API change. A
`BREAKING CHANGE` can be part of commits of any type (see an [example commit message](https://github.com/ewcloud/ewc-flavours/commit/7c43a7975bb18ff999c85bd0f85353698472fc0d)).

## Reporting Security Vulnerabilities

Due to their public nature, GitHub and RocketChat are not appropriate places
for reporting vulnerabilities. If you suspect you have found a security
vulnerability, please do not file a GitHub issue, but instead email
[support@europeanweather.cloud](mailto:support@europeanweather.cloud) with the
full details, including steps to reproduce the issue.
