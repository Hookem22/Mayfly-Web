using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web;
using System.Web.Http;

public class AzureService
{
    HttpClient client;
    string key = "NzEvHltvEcuInDmQsnXqReEIitsWIa99";
    string _tableName;
    public AzureService(string tableName)
    {
        client = new HttpClient();
        client.DefaultRequestHeaders.Add("X-ZUMO-APPLICATION", key);
        client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        _tableName = tableName;
    }

    public string Get(string id)
    {
        return client.GetStringAsync(string.Format("https://mayflyapp.azure-mobile.net/tables/{0}/{1}", _tableName, id)).Result;
    }

    public string Get()
    {
        return client.GetStringAsync(string.Format("https://mayflyapp.azure-mobile.net/tables/{0}", _tableName)).Result;
    }

    public string GetByProc(string procName, string parameters)
    {
        return client.GetStringAsync(string.Format("https://mayflyapp.azure-mobile.net/api/{0}?{1}", procName, parameters)).Result;
    }

    public string GetByWhere(string whereStatement)
    {
        return client.GetStringAsync(string.Format("https://mayflyapp.azure-mobile.net/tables/{0}/?$filter={1}", _tableName, whereStatement)).Result;
    }

    public string Post(dynamic obj)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, string.Format("https://mayflyapp.azure-mobile.net/tables/{0}", _tableName));
        request.Content = new StringContent(obj, Encoding.UTF8, "application/json");

        var data = client.SendAsync(request).Result;

        if (!data.IsSuccessStatusCode)
            throw new HttpResponseException(data.StatusCode);

        string idString = data.Headers.Location.AbsoluteUri;
        return idString.Substring(idString.LastIndexOf("/") + 1);
    }


    public void Put(string id, dynamic obj)
    {
        var request = new HttpRequestMessage(new HttpMethod("PATCH"), string.Format("https://mayflyapp.azure-mobile.net/tables/{0}/{1}", _tableName, id));
        request.Content = new StringContent(obj, Encoding.UTF8, "application/json");

        var data = client.SendAsync(request).Result;

        if (!data.IsSuccessStatusCode)
            throw new HttpResponseException(data.StatusCode);
    }

    public void Delete(string id)
    {
        var request = new HttpRequestMessage(HttpMethod.Delete, "https://mayflyapp.azure-mobile.net/tables/Place/" + id);
        var data = client.SendAsync(request).Result;

        if (!data.IsSuccessStatusCode)
            throw new HttpResponseException(data.StatusCode);
    }

}