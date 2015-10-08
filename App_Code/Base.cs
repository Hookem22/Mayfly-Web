using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using System.IO;

public abstract class Base<T>
{
    [JsonProperty("id")]
    public string Id { get; set; }

    static string _azureTable;

    static string AzureTable
    {
        get
        {
            if (string.IsNullOrEmpty(_azureTable))
            {
                T item = (T)typeof(T).GetConstructor(new Type[] { }).Invoke(new object[0]);
                //_azureTable = typeof(T).GetProperty("AzureTable").GetValue(item).ToString();
            }
            return _azureTable;
        }
        set { _azureTable = value; }
    }

    public Base(string azureTable)
    {
        _azureTable = azureTable;
    }

    public static T Get(string id)
    {
        AzureService service = new AzureService(AzureTable);
        var data = service.Get(id);
        T item = JsonConvert.DeserializeObject<T>(data);
        return item;
    }

    public static List<T> Get()
    {
        AzureService service = new AzureService(AzureTable);
        var data = service.Get();
        IEnumerable<T> items = JsonConvert.DeserializeObject<IEnumerable<T>>(data);
        return items.ToList();
    }

    protected static List<T> GetByWhere(string whereStatement)
    {
        AzureService service = new AzureService(AzureTable);
        var data = service.GetByWhere(whereStatement);
        IEnumerable<T> items = JsonConvert.DeserializeObject<IEnumerable<T>>(data);
        return items.ToList();
    }

    protected static List<T> GetByProc(string procName, string parameters)
    {
        AzureService service = new AzureService(AzureTable);
        var data = service.GetByProc(procName, parameters);
        IEnumerable<T> items = JsonConvert.DeserializeObject<IEnumerable<T>>(data);
        return items.ToList();
    }

    protected static List<T> GetByProcFast(string procName, string parameters)
    {
        AzureService service = new AzureService(AzureTable);
        var data = service.GetByProc(procName, parameters);
        return DeserializeJson(data, typeof(T));
    }

    public void Save()
    {
        AzureService service = new AzureService(AzureTable);
        T obj = (T)this.MemberwiseClone();
        if (string.IsNullOrEmpty(this.Id))
        {
            foreach (var prop in typeof(T).GetProperties())
            {
                if (prop.Name == "Id" || prop.GetCustomAttributes(typeof(NonSave), false).Length > 0)
                    prop.SetValue(obj, null);
            }

            var json = JsonConvert.SerializeObject(obj, new JsonSerializerSettings() { NullValueHandling = NullValueHandling.Ignore });
            this.Id = service.Post(json);
        }
        else
        {
            foreach (var prop in typeof(T).GetProperties())
            {
                if (prop.GetCustomAttributes(typeof(NonSave), false).Length > 0)
                    prop.SetValue(obj, null);
            }

            var json = JsonConvert.SerializeObject(obj, new JsonSerializerSettings() { NullValueHandling = NullValueHandling.Ignore });
            service.Put(this.Id, json);
        }
    }

    public void Delete()
    {
        AzureService service = new AzureService(AzureTable);
        service.Delete(this.Id);
    }

    private static List<T> DeserializeJson(string data, Type type)
    {
        List<T> list = new List<T>();
        while (data.Contains("}"))
        {
            T obj = (T)Activator.CreateInstance(type);
            list.Add(obj);
            string json = data.Substring(0, data.IndexOf("}") + 1);
            data = data.Substring(data.IndexOf("}") + 1);
            foreach (var prop in typeof(T).GetProperties())
            {
                var propName = string.Format("\"{0}\":", prop.Name.ToLower());
                if (json.Contains(propName))
                {
                    string val = null;
                    if (prop.PropertyType.Name == "String")
                    {
                        val = json.Substring(json.IndexOf(propName) + propName.Length + 1);
                        if (val.Contains("\",\""))
                            val = val.Substring(0, val.IndexOf("\",\""));
                        else
                            val = val.Substring(0, val.IndexOf("\"}"));
                    }
                    else
                    {
                        val = json.Substring(json.IndexOf(propName) + propName.Length);
                        if (val.Contains(",\""))
                            val = val.Substring(0, val.IndexOf(",\""));
                        else
                            val = val.Substring(0, val.IndexOf("}"));
                    }
                    if (prop.PropertyType.Name == "String")
                        prop.SetValue(obj, val);
                    else if (prop.PropertyType.Name == "DateTime")
                        prop.SetValue(obj, DateTime.Parse(val));
                    else if (prop.PropertyType.Name == "Double")
                        prop.SetValue(obj, double.Parse(val));
                    else if (prop.PropertyType.Name == "Int32")
                        prop.SetValue(obj, int.Parse(val));
                    else if (prop.PropertyType.Name == "Bool")
                        prop.SetValue(obj, bool.Parse(val));
                }
            }
        }
        return list;
    }

}