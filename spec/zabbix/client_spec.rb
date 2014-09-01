describe Zabbix::Client do
  context "when call procedure" do
    it do
      run_client do |client|
        result = client.apiinfo.version
        expect(result["body"]).to eq "{\"jsonrpc\":\"2.0\",\"method\":\"apiinfo.version\",\"params\":[],\"id\":1}"
      end
    end

    it do
      run_client do |client|
        result = client.item.get(:itemids => [1, 2, 3])
        expect(result["body"]).to eq "{\"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"itemids\":[1,2,3]},\"id\":1}"
      end
    end

    it do
      run_client do |client|
        result = client.item.delete([1, 2, 3])
        expect(result["body"]).to eq "{\"jsonrpc\":\"2.0\",\"method\":\"item.delete\",\"params\":[1,2,3],\"id\":1}"
      end
    end
  end

  context "login/logout" do
    it do
      run_client do |client|
        client.user.login(:user => "scott", :password => "tiger")

        result = client.apiinfo.version
        expect(result["body"]).to eq "{\"jsonrpc\":\"2.0\",\"method\":\"apiinfo.version\",\"params\":[],\"id\":1}"

        result = client.item.get(:itemids => [1, 2, 3])
        expect(result["body"]).to eq "{\"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"itemids\":[1,2,3]},\"id\":1,\"auth\":{\"body\":\"{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"method\\\":\\\"user.login\\\",\\\"params\\\":{\\\"user\\\":\\\"scott\\\",\\\"password\\\":\\\"tiger\\\"},\\\"id\\\":1}\",\"header\":{\"content-type\":[\"application/json-rpc\"],\"accept-encoding\":[\"gzip;q=1.0,deflate;q=0.6,identity;q=0.3\"],\"accept\":[\"*/*\"],\"user-agent\":[\"Ruby\"],\"host\":[\"localhost:20080\"],\"content-length\":[\"91\"]}}}"

        client.user.logout

        result = client.item.get(:itemids => [1, 2, 3])
        expect(result["body"]).to eq "{\"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"itemids\":[1,2,3]},\"id\":1}"
      end
    end
  end

  context "when error happen" do
    it do
      handler = proc do |req, res|
        res.status = 500
        res.body = JSON.dump(:error => {:code => -1, :message => 'Any Error'})
      end

      run_client(:handler => handler) do |client|
        expect {
          client.item.get(:itemids => [1, 2, 3])
        }.to raise_error(Zabbix::Client::Error, '{"code"=>-1, "message"=>"Any Error", "method"=>"item.get", "params"=>{:itemids=>[1, 2, 3]}}')
      end
    end

    it do
      handler = proc do |req, res|
        res.status = 404
        res.body = 'Not Found'
      end

      run_client(:handler => handler) do |client|
        expect {
          client.item.get(:itemids => [1, 2, 3])
        }.to raise_error(Net::HTTPServerException, '404 "Not Found "')
      end
    end

    it do
      handler = proc do |req, res|
        res.status = 200
        res.body = 'non-JSON data'
      end

      run_client(:handler => handler) do |client|
        expect {
          client.item.get(:itemids => [1, 2, 3])
        }.to raise_error(RuntimeError, '200 "OK " non-JSON data')
      end
    end
  end

  context "when add header" do
    it do
      run_client do |client|
        result = client.item.get({:itemids => [1, 2, 3]}, :headers => {"User-Agent" => "Any User Agent"})
        expect(result["header"]["user-agent"]).to eq ["Any User Agent"]
      end
    end

    it do
      run_client(:headers => {"User-Agent" => "Any User Agent"}) do |client|
        result = client.apiinfo.version
        expect(result["header"]["user-agent"]).to eq ["Any User Agent"]
      end
    end
  end

  context "when use proxy" do
    it do
      proxy do |proxy_host, proxy_port|
        run_client(:proxy_host => proxy_host, :proxy_port => proxy_port) do |client|
          result = client.item.get(:itemids => [1, 2, 3])
          expect(result["body"]).to eq "{\"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"itemids\":[1,2,3]},\"id\":1}"
        end
      end
    end
  end

  context "when basic auth" do
    it do
      run_client(:basic_auth => ["scott", "tiger"], :basic_auth_user => "scott", :basic_auth_password => "tiger") do |client|
        result = client.item.get(:itemids => [1, 2, 3])
        expect(result["body"]).to eq "{\"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"itemids\":[1,2,3]},\"id\":1}"
      end
    end
  end

  context "when https" do
    it do
      run_client(:ssl => true) do |client|
        result = client.item.get(:itemids => [1, 2, 3])
        expect(result["body"]).to eq "{\"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"itemids\":[1,2,3]},\"id\":1}"
      end
    end
  end
end
