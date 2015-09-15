using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Group
/// </summary>
public class Group : Base<Group>
{
    public Group() : base("Group")
    {

    }

    #region Properties

    public string Name { get; set; }

    public string Description { get; set; }



    #endregion

    public static List<Group> Get()
    {
        Group group1 = new Group();
        group1.Name = "South Austin Board Games";

        Group group2 = new Group();
        group2.Name = "Austin Disc";

        List<Group> groups = new List<Group> { group1, group2 };
        return groups;
    }
}