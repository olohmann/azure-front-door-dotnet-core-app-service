using System;
using System.Net;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Authorization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.Extensions.Logging;
using Microsoft.Identity.Web;

namespace AspNetCoreSampleAppAAD
{
    public class Startup
    {
        public Startup(IConfiguration configuration, IWebHostEnvironment env)
        {
            Configuration = configuration;
            _env = env;
        }

        public IConfiguration Configuration { get; }
        private readonly IWebHostEnvironment _env;


        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            // Sign-in users with the Microsoft identity platform
            services.AddMicrosoftIdentityWebAppAuthentication(Configuration);

            services.AddControllersWithViews(options =>
            {
                var policy = new AuthorizationPolicyBuilder()
                    .RequireAuthenticatedUser()
                    .Build();
                options.Filters.Add(new AuthorizeFilter(policy));
            });
            services.AddRazorPages();

            if (!_env.IsDevelopment())
            {
                services.Configure<ForwardedHeadersOptions>(options =>
                {
                    options.ForwardedHeaders =
                        ForwardedHeaders.All;

                    options.RequireHeaderSymmetry = false;
                    options.ForwardLimit = null;

                    // Only loopback proxies are allowed by default.
                    // Clear that restriction because forwarders are enabled by explicit 
                    // configuration.
                    // Network mitigation is being handled via AppService Network Restrictions.
                    options.KnownNetworks.Clear();
                    options.KnownProxies.Clear();
                });
            }

            services.AddHealthChecks();

        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, ILogger<Startup> logger)
        {
            if (!_env.IsDevelopment())
            {
                // Ensure the "right" Front Door is calling.
                var expectedFdid = Configuration.GetValue<string>("X_AZURE_FDID");
                if (!string.IsNullOrWhiteSpace(expectedFdid))
                {
                    app.Use(async (context, next) =>
                    {
                        context.Request.Headers.TryGetValue("X-Azure-FDID", out var actualFdid);
                        if (actualFdid == expectedFdid)
                        {
                            await next();
                        }
                        else
                        {
                            logger.LogWarning("Abort request due to missing X-Azure-FDID",
                                context.Connection.RemoteIpAddress);
                            context.Response.StatusCode = (int) HttpStatusCode.BadGateway;
                            await context.Response.WriteAsync("Bad Gateway");
                        }
                    });
                }
                
                app.UseForwardedHeaders();
            }
            
            var debugReverseProxy = Configuration.GetValue<string>("DEBUG_REVERSE_PROXY");
            if (!string.IsNullOrWhiteSpace(debugReverseProxy))
            {
                app.Run(async (context) =>
                {
                    context.Response.ContentType = "text/plain";

                    // Request method, scheme, and path
                    await context.Response.WriteAsync(
                        $"Request Method: {context.Request.Method}{Environment.NewLine}");
                    await context.Response.WriteAsync(
                        $"Request Scheme: {context.Request.Scheme}{Environment.NewLine}");
                    await context.Response.WriteAsync(
                        $"Request Path: {context.Request.Path}{Environment.NewLine}");

                    // Headers
                    await context.Response.WriteAsync($"Request Headers:{Environment.NewLine}");

                    foreach (var header in context.Request.Headers)
                    {
                        await context.Response.WriteAsync($"{header.Key}: " +
                                                          $"{header.Value}{Environment.NewLine}");
                    }

                    await context.Response.WriteAsync(Environment.NewLine);

                    // Connection: RemoteIp
                    await context.Response.WriteAsync(
                        $"Request RemoteIp: {context.Connection.RemoteIpAddress}");
                }); 
            }
            
            app.UseHealthChecks("/health");
            
            if (_env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }
            app.UseHttpsRedirection();
            app.UseStaticFiles();

            app.UseRouting();

            app.UseAuthentication();
            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllerRoute(
                    name: "default",
                    pattern: "{controller=Home}/{action=Index}/{id?}");
                endpoints.MapRazorPages();
            });
        }
    }
}