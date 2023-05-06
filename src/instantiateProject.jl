# instantiate a project

using Pkg
Pkg.add("PkgTemplates")

using PkgTemplates
t = Template(;
           user="sachavarone",
           authors=["Sacha Varone"],
           plugins=[
               License(name="MIT"),
               Git(),
               GitHubActions(),
           ],
       )
# Template(; user="user", disable_defaults=[Git]) to disable all Git interactions

t("passeportvacances")
