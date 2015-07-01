using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

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

    public void Save()
    {
        AzureService service = new AzureService(AzureTable);
        if (string.IsNullOrEmpty(this.Id))
        {
            var obj = JsonConvert.SerializeObject(this, new JsonSerializerSettings() { NullValueHandling = NullValueHandling.Ignore });
            this.Id = service.Post(obj);
        }
        else
        {
            var obj = JsonConvert.SerializeObject(this);
            service.Put(this.Id, obj);
        }
    }

    public void Delete()
    {
        AzureService service = new AzureService(AzureTable);
        service.Delete(this.Id);
    }
}